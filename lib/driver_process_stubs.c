/* Windows-specific driver plumbing. The parent ends are overlapped named
 * pipes; the child sees ordinary synchronous, binary stdin/stdout handles.
 * Polling never blocks the Eio domain. Only spawn and cancellation retirement
 * can block, and their OCaml callers use Eio_unix.run_in_systhread.
 */
#ifdef _WIN32
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0602
#endif
#include <windows.h>
#include <wchar.h>
#endif
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/threads.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#define PW_BUFFER_SIZE 65536

typedef struct {
    HANDLE handle;
    OVERLAPPED overlapped;
    int pending;
    DWORD length, offset;
    unsigned char buffer[PW_BUFFER_SIZE];
} pw_pipe;

typedef struct {
    HANDLE process, job;
    pw_pipe input, output;
} pw_process;

#define Process_val(v) (*(pw_process **)Data_custom_val(v))

static void pw_error(const char *operation, DWORD error)
{
    char message[192];
    snprintf(message, sizeof(message), "Playwright %s: Windows error %lu",
             operation, (unsigned long)error);
    caml_failwith(message);
}

static void pw_close_handle(HANDLE *handle)
{
    if (*handle && *handle != INVALID_HANDLE_VALUE) CloseHandle(*handle);
    *handle = NULL;
}

/* Do not free or reuse the OVERLAPPED/buffer until cancellation has completed. */
static void pw_close_pipe(pw_pipe *pipe)
{
    if (pipe->pending) {
        DWORD transferred;
        CancelIoEx(pipe->handle, &pipe->overlapped);
        GetOverlappedResult(pipe->handle, &pipe->overlapped, &transferred, TRUE);
        pipe->pending = 0;
    }
    pw_close_handle(&pipe->handle);
    pw_close_handle(&pipe->overlapped.hEvent);
}

static void pw_dispose(pw_process *process)
{
    /* KILL_ON_JOB_CLOSE is also the fallback for interrupted startup. */
    pw_close_handle(&process->job);
    pw_close_pipe(&process->input);
    pw_close_pipe(&process->output);
    pw_close_handle(&process->process);
    free(process);
}

static void pw_finalize(value v)
{
    pw_process *process = Process_val(v);
    if (process) {
        Process_val(v) = NULL;
        pw_dispose(process);
    }
}

static struct custom_operations pw_ops = {
    .identifier = "playwright.windows.process",
    .finalize = pw_finalize,
    .compare = custom_compare_default,
    .hash = custom_hash_default,
    .serialize = custom_serialize_default,
    .deserialize = custom_deserialize_default,
    .compare_ext = custom_compare_ext_default,
    .fixed_length = custom_fixed_length_default
};

static pw_process *pw_get(value v)
{
    pw_process *process = Process_val(v);
    if (!process) caml_invalid_argument("Playwright process is closed");
    return process;
}

/* The client is opened before ConnectNamedPipe. ERROR_PIPE_CONNECTED is the
 * expected successful connection; no asynchronous connect remains outstanding. */
static DWORD pw_make_pipe(pw_pipe *parent, HANDLE *child, int parent_writes)
{
    static volatile LONG counter = 0;
    wchar_t name[128];
    SECURITY_ATTRIBUTES inherit = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
    OVERLAPPED connection = {0};
    DWORD error = ERROR_SUCCESS;
    swprintf(name, 128, L"\\\\.\\pipe\\playwright-ocaml-%lu-%lu",
             (unsigned long)GetCurrentProcessId(),
             (unsigned long)InterlockedIncrement(&counter));
    parent->overlapped.hEvent = CreateEventW(NULL, TRUE, FALSE, NULL);
    if (!parent->overlapped.hEvent) return GetLastError();
    parent->handle = CreateNamedPipeW(
        name, (parent_writes ? PIPE_ACCESS_OUTBOUND : PIPE_ACCESS_INBOUND) |
              FILE_FLAG_OVERLAPPED | FILE_FLAG_FIRST_PIPE_INSTANCE,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT | PIPE_REJECT_REMOTE_CLIENTS,
        1, PW_BUFFER_SIZE, PW_BUFFER_SIZE, 0, NULL);
    if (parent->handle == INVALID_HANDLE_VALUE) return GetLastError();
    *child = CreateFileW(name, parent_writes ? GENERIC_READ : GENERIC_WRITE,
                         0, &inherit, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (*child == INVALID_HANDLE_VALUE) return GetLastError();
    connection.hEvent = CreateEventW(NULL, TRUE, FALSE, NULL);
    if (!connection.hEvent) return GetLastError();
    if (!ConnectNamedPipe(parent->handle, &connection)) {
        error = GetLastError();
        if (error == ERROR_PIPE_CONNECTED) error = ERROR_SUCCESS;
        else if (error == ERROR_IO_PENDING) {
            DWORD transferred;
            if (GetOverlappedResult(parent->handle, &connection, &transferred, TRUE))
                error = ERROR_SUCCESS;
            else error = GetLastError();
        }
    }
    CloseHandle(connection.hEvent);
    return error;
}

CAMLprim value playwright_windows_spawn(value command_value)
{
    CAMLparam1(command_value);
    CAMLlocal1(result);
    pw_process *process;
    wchar_t *command = NULL, *executable = NULL;
    HANDLE child_in = NULL, child_out = NULL, child_err = NULL;
    HANDLE inherited[3];
    STARTUPINFOEXW startup = {0};
    PROCESS_INFORMATION info = {0};
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = {0};
    SIZE_T attributes_size = 0;
    DWORD error = ERROR_SUCCESS, size, found;
    int command_size, attributes_initialized = 0;
    SECURITY_ATTRIBUTES inherit = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };

    result = caml_alloc_custom(&pw_ops, sizeof(pw_process *),
                               sizeof(pw_process), 1024 * 1024);
    Process_val(result) = NULL;
    process = calloc(1, sizeof(*process));
    if (!process) caml_raise_out_of_memory();
    Process_val(result) = process;
    command_size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                       String_val(command_value), -1, NULL, 0);
    if (!command_size) pw_error("UTF-8 command line", GetLastError());
    command = malloc((size_t)command_size * sizeof(wchar_t));
    if (!command) caml_raise_out_of_memory();
    if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                            String_val(command_value), -1, command, command_size)) {
        error = GetLastError();
        free(command);
        pw_error("UTF-8 command line", error);
    }

    caml_enter_blocking_section();
    size = SearchPathW(NULL, L"node.exe", NULL, 0, NULL, NULL);
    if (!size) { error = GetLastError(); goto done; }
    executable = malloc(((size_t)size + 1) * sizeof(wchar_t));
    if (!executable) { error = ERROR_NOT_ENOUGH_MEMORY; goto done; }
    found = SearchPathW(NULL, L"node.exe", NULL, size + 1, executable, NULL);
    if (!found) { error = GetLastError(); goto done; }
    if (found >= size + 1) { error = ERROR_INSUFFICIENT_BUFFER; goto done; }
    error = pw_make_pipe(&process->input, &child_in, 1);
    if (error) goto done;
    error = pw_make_pipe(&process->output, &child_out, 0);
    if (error) goto done;

    if (!DuplicateHandle(GetCurrentProcess(), GetStdHandle(STD_ERROR_HANDLE),
                         GetCurrentProcess(), &child_err, 0, TRUE, DUPLICATE_SAME_ACCESS)) {
        child_err = CreateFileW(L"NUL", GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
                                &inherit, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        if (child_err == INVALID_HANDLE_VALUE) { error = GetLastError(); goto done; }
    }

    process->job = CreateJobObjectW(NULL, NULL);
    if (!process->job) { error = GetLastError(); goto done; }
    limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!SetInformationJobObject(process->job, JobObjectExtendedLimitInformation,
                                 &limits, sizeof(limits))) {
        error = GetLastError(); goto done;
    }

    InitializeProcThreadAttributeList(NULL, 1, 0, &attributes_size);
    startup.lpAttributeList = malloc(attributes_size);
    if (!startup.lpAttributeList) { error = ERROR_NOT_ENOUGH_MEMORY; goto done; }
    if (!InitializeProcThreadAttributeList(startup.lpAttributeList, 1, 0, &attributes_size)) {
        error = GetLastError(); goto done;
    }
    attributes_initialized = 1;
    inherited[0] = child_in; inherited[1] = child_out; inherited[2] = child_err;
    if (!UpdateProcThreadAttribute(startup.lpAttributeList, 0,
            PROC_THREAD_ATTRIBUTE_HANDLE_LIST, inherited, sizeof(inherited), NULL, NULL)) {
        error = GetLastError(); goto done;
    }
    startup.StartupInfo.cb = sizeof(startup);
    startup.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
    startup.StartupInfo.hStdInput = child_in;
    startup.StartupInfo.hStdOutput = child_out;
    startup.StartupInfo.hStdError = child_err;
    if (!CreateProcessW(executable, command, NULL, NULL, TRUE,
                        CREATE_SUSPENDED | CREATE_NO_WINDOW | EXTENDED_STARTUPINFO_PRESENT,
                        NULL, NULL, &startup.StartupInfo, &info)) {
        error = GetLastError(); goto done;
    }
    process->process = info.hProcess;
    /* Assign before running any Node code, so descendants cannot escape. */
    if (!AssignProcessToJobObject(process->job, process->process) ||
        ResumeThread(info.hThread) == (DWORD)-1) {
        error = GetLastError();
        TerminateProcess(process->process, 1);
        WaitForSingleObject(process->process, INFINITE);
        goto done;
    }

done:
    pw_close_handle(&info.hThread);
    pw_close_handle(&child_in);
    pw_close_handle(&child_out);
    pw_close_handle(&child_err);
    if (attributes_initialized) DeleteProcThreadAttributeList(startup.lpAttributeList);
    free(startup.lpAttributeList);
    free(command);
    free(executable);
    if (error) pw_dispose(process);
    caml_leave_blocking_section();
    if (error) {
        Process_val(result) = NULL;
        pw_error("starting node.exe (is Node.js on PATH?)", error);
    }
    CAMLreturn(result);
}

CAMLprim value playwright_windows_read(value v, value requested)
{
    CAMLparam2(v, requested);
    CAMLlocal2(data, some);
    pw_pipe *pipe = &pw_get(v)->output;
    DWORD transferred = 0, error, length;
    if (!pipe->handle) caml_invalid_argument("Playwright stdout is closed");
    if (Long_val(requested) <= 0) caml_invalid_argument("Empty Playwright read");
    if (pipe->offset == pipe->length) {
        pipe->offset = pipe->length = 0;
        if (!pipe->pending) {
            ResetEvent(pipe->overlapped.hEvent);
            if (ReadFile(pipe->handle, pipe->buffer, PW_BUFFER_SIZE,
                         &transferred, &pipe->overlapped)) pipe->length = transferred;
            else {
                error = GetLastError();
                if (error == ERROR_IO_PENDING) pipe->pending = 1;
                else if (error != ERROR_BROKEN_PIPE) pw_error("reading stdout", error);
            }
        }
        if (pipe->pending) {
            if (!GetOverlappedResult(pipe->handle, &pipe->overlapped, &transferred, FALSE)) {
                error = GetLastError();
                if (error == ERROR_IO_INCOMPLETE) CAMLreturn(Val_none);
                pipe->pending = 0;
                if (error != ERROR_BROKEN_PIPE) pw_error("reading stdout", error);
                transferred = 0;
            }
            pipe->pending = 0;
            pipe->length = transferred;
        }
    }
    length = pipe->length - pipe->offset;
    if ((uintnat)Long_val(requested) < length) length = (DWORD)Long_val(requested);
    data = caml_alloc_initialized_string(length, (char *)pipe->buffer + pipe->offset);
    pipe->offset += length;
    some = caml_alloc_some(data);
    CAMLreturn(some);
}

CAMLprim value playwright_windows_write_start(value v, value data)
{
    CAMLparam2(v, data);
    pw_pipe *pipe = &pw_get(v)->input;
    DWORD length = (DWORD)caml_string_length(data), transferred = 0, error;
    if (!pipe->handle) caml_invalid_argument("Playwright stdin is closed");
    if (pipe->pending || pipe->length) caml_invalid_argument("Concurrent Playwright write");
    if (length == 0 || length > PW_BUFFER_SIZE) caml_invalid_argument("Playwright write size");
    memcpy(pipe->buffer, String_val(data), length);
    ResetEvent(pipe->overlapped.hEvent);
    if (WriteFile(pipe->handle, pipe->buffer, length, &transferred, &pipe->overlapped))
        pipe->length = transferred;
    else {
        error = GetLastError();
        if (error != ERROR_IO_PENDING) pw_error("writing stdin", error);
        pipe->pending = 1;
    }
    CAMLreturn(Val_unit);
}

CAMLprim value playwright_windows_write_poll(value v)
{
    CAMLparam1(v);
    CAMLlocal1(some);
    pw_pipe *pipe = &pw_get(v)->input;
    DWORD transferred = pipe->length, error;
    if (!pipe->handle) caml_invalid_argument("Playwright stdin is closed");
    if (pipe->pending) {
        if (!GetOverlappedResult(pipe->handle, &pipe->overlapped, &transferred, FALSE)) {
            error = GetLastError();
            if (error == ERROR_IO_INCOMPLETE) CAMLreturn(Val_none);
            pipe->pending = 0;
            pw_error("writing stdin", error);
        }
        pipe->pending = 0;
    }
    pipe->length = 0;
    if (!transferred) caml_failwith("Playwright stdin write made no progress");
    some = caml_alloc_some(Val_long(transferred));
    CAMLreturn(some);
}

CAMLprim value playwright_windows_poll_exit(value v)
{
    CAMLparam1(v);
    CAMLlocal1(some);
    pw_process *process = pw_get(v);
    DWORD status, wait = WaitForSingleObject(process->process, 0);
    if (wait == WAIT_TIMEOUT) CAMLreturn(Val_none);
    if (wait == WAIT_FAILED || !GetExitCodeProcess(process->process, &status))
        pw_error("waiting for driver", GetLastError());
    some = caml_alloc_some(Val_long(status));
    CAMLreturn(some);
}

CAMLprim value playwright_windows_kill(value v)
{
    CAMLparam1(v);
    pw_process *process = pw_get(v);
    if (!TerminateJobObject(process->job, 1)) pw_error("terminating driver job", GetLastError());
    CAMLreturn(Val_unit);
}

CAMLprim value playwright_windows_close_input(value v)
{
    CAMLparam1(v);
    pw_process *process = pw_get(v);
    caml_enter_blocking_section();
    pw_close_pipe(&process->input);
    caml_leave_blocking_section();
    CAMLreturn(Val_unit);
}

CAMLprim value playwright_windows_close_output(value v)
{
    CAMLparam1(v);
    pw_process *process = pw_get(v);
    caml_enter_blocking_section();
    pw_close_pipe(&process->output);
    caml_leave_blocking_section();
    CAMLreturn(Val_unit);
}

CAMLprim value playwright_windows_close(value v)
{
    CAMLparam1(v);
    pw_process *process = Process_val(v);
    Process_val(v) = NULL;
    if (process) {
        caml_enter_blocking_section();
        pw_dispose(process);
        caml_leave_blocking_section();
    }
    CAMLreturn(Val_unit);
}
#else
/* Keep native Unix builds independent of Windows headers and libraries. */
#define PW_UNAVAILABLE(name) \
    CAMLprim value name(value v) { (void)v; caml_failwith("Windows-only driver operation"); }
#define PW_UNAVAILABLE2(name) \
    CAMLprim value name(value v, value w) { (void)v; (void)w; caml_failwith("Windows-only driver operation"); }
PW_UNAVAILABLE(playwright_windows_spawn)
PW_UNAVAILABLE2(playwright_windows_read)
PW_UNAVAILABLE2(playwright_windows_write_start)
PW_UNAVAILABLE(playwright_windows_write_poll)
PW_UNAVAILABLE(playwright_windows_poll_exit)
PW_UNAVAILABLE(playwright_windows_kill)
PW_UNAVAILABLE(playwright_windows_close_input)
PW_UNAVAILABLE(playwright_windows_close_output)
PW_UNAVAILABLE(playwright_windows_close)
#endif
