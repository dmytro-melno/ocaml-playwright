(* An HTTPS server that tells which certificate its client showed, for the tests of client
   certificates.  It is a script for Node.js, which is there because the driver runs on it. *)

open Eio.Std

(* A self-signed certificate with its key, which is of use to these tests only:

   openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 36500 \
       -subj "/CN=ocaml-playwright-test" -keyout key.pem -out cert.pem
   openssl pkcs12 -export -inkey key.pem -in cert.pem -out client.pfx -passout pass:secret *)

let common_name = "ocaml-playwright-test"

let certificate = {|-----BEGIN CERTIFICATE-----
MIIBljCCAT2gAwIBAgIUE8LLcZfY7za3E/ueoPqspoDkrCowCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVb2NhbWwtcGxheXdyaWdodC10ZXN0MCAXDTI2MTExMTIxNTU0
OFoYDzIxMjYxMDE4MjE1NTQ4WjAgMR4wHAYDVQQDDBVvY2FtbC1wbGF5d3JpZ2h0
LXRlc3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASw9V40lZclkeFZ2r63ZjoH
ee6tAQ8DmkY2UknVASIqgf7iKBqMkzDwgS0NR14Uafvmlv0cH+I+20Htb3TEoflr
o1MwUTAdBgNVHQ4EFgQUP9a5lVdcRgYNFCLic74V9qe2WSMwHwYDVR0jBBgwFoAU
P9a5lVdcRgYNFCLic74V9qe2WSMwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQD
AgNHADBEAiA7NfZ0G1P5k8ay2RirkQIDOzstTinDwsXqbfIBo4oZ/QIgXH+eubOt
7PQqtV7ZAnkT3DrM+3s3+xtxavkJg3YwMSo=
-----END CERTIFICATE-----
|}

let private_key = {|-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg/ulEHW1ofQ4Ej7uC
VYAooMcmoKqzhV8KRFXGmflTCiuhRANCAASw9V40lZclkeFZ2r63ZjoHee6tAQ8D
mkY2UknVASIqgf7iKBqMkzDwgS0NR14Uafvmlv0cH+I+20Htb3TEoflr
-----END PRIVATE KEY-----
|}

let archive_passphrase = "secret"

(* The same two as a PFX archive, which is binary. *)
let archive =
    let hex =
        String.concat ""
            (String.split_on_char ' '
                 (String.concat "" (String.split_on_char '\n' {|
           30820444020103308203f206092a864886f70d010701a08203e3048203df308203db3082028a06092a864886f70d010706a082027b30820277020100
           3082027006092a864886f70d010701305f06092a864886f70d01050d3052303106092a864886f70d01050c302404101792357afc3abcab64500d415d
           db6ac602020800300c06082a864886f70d02090500301d060960864801650304012a0410f8e8556a136e2437f04d9463a17e2f8f8082020069843d33
           70c9367b1d681574a4c61819173b0bb5471bc36d098a43e770754b22f97174a0f762e70e0dd1aab6e781ff62bdb33ec88bf1db377afec7b56bb33f46
           346e5d0a259c8d46eddea3908c9ec7c3ee6b78c5b5092f92d3d734c18699e3d669675c204b7620a1f293554412a0812d574fd4a788b1814842ed78de
           15cb9772160783c8ab9a8c3c4f5b896463a08639993e12b55039f0813325aa7f8e8fe813f2e0683314f59bcac40860404fc51a7818b8e2953b952d1c
           6c8e894cf2f16da5443473bdd44995327e8fbd0a267f5dcf15d462dda84857d08b4d7da64adaa0afc3e259d9302064c481d0b23084099c5fc421ab81
           7244f855b154123a9ccd98cf467d4d8e13209e17f442e648d6fe3c315cebe855b5efe2cee014c9ff71a443482ac906f0171f0871e646200c64e0aaaf
           eaee3e248cf305ed73c944aa88ee93607eb133427f18f68137fbc5610f82549fe3cd7513a26319a6d914edcc4a134da7afc055648374f8e0acb2086b
           7f79155ea978950a9dc891e1dbf5fdc2c635b46bbc98ca40300baaab0294b4ff5bbe01977c16e14a5351097a47e3dbe322c9ccb0e325d2066946dd64
           cc5e880ca3fd83777b35fc98f4350e7ddb6331f8aa82cdea5d0f4dbfa422bb3131903b2bd6e03c24febb2cfc88000b0267d8e0019948c91203c3bf28
           fa8facc3d89caa227877b7b6de7097fe389b211732b6f1307371e9473082014906092a864886f70d010701a082013a04820136308201323082012e06
           0b2a864886f70d010c0a0102a081f73081f4305f06092a864886f70d01050d3052303106092a864886f70d01050c30240410ee4e0f98b5111691f7a8
           1ab43140c9b502020800300c06082a864886f70d02090500301d060960864801650304012a0410a675fc20a87b541cbe39e032e00e213604819064a3
           2f7c3dd834492b6ec49c01526e99cc9efc832c2f1d6c861d62bf4d65f967c087cc33390088072a8fa21a61806edca5521eb63c1aa829d5310a17cd7f
           269a67480ea6b6f996120e601d477b3d52993f339dc384ad876b2f869b3a66ed4a19b7317e2de5cff0cdee68792fcd888ff15a9e2b9a3bbd21a4d69b
           34c2b4af3c3cfd0c0634f9119a819166f38cb6a3a07a3125302306092a864886f70d0109153116041476c70909b0f3a395c960c6d9c0a56047bf3554
           5d30493031300d060960864801650304020105000420ac59e84c9e7bc416605c872ab530175310afe80d9998da97666cefaaef4590850410807e218a
           4b60dd308a4e828ac409828802020800|})))
    in
    String.init (String.length hex / 2) (fun i -> Char.chr (int_of_string ("0x" ^ String.sub hex (2 * i) 2)))

let script = {|
const https = require('https');
const fs = require('fs');
const [cert, key] = process.argv.slice(1);
const options = { cert: fs.readFileSync(cert), key: fs.readFileSync(key), requestCert: true, rejectUnauthorized: false };
const server = https.createServer(options, (request, response) => {
    const subject = request.socket.getPeerCertificate().subject;
    response.end('client: ' + (subject ? subject.CN : 'nobody'));
});
server.listen(0, '127.0.0.1', () => console.log(server.address().port));
|}

let node () = Option.value (Sys.getenv_opt "PLAYWRIGHT_NODEJS_PATH") ~default:"node"

(* [run env ~cert ~key f] calls [f] with the origin of a server that shows the certificate in the
   file [cert], asks its clients for theirs, accepts any, and answers every request with
   ["client: "] and the common name of that certificate, or ["nobody"]. *)
let run env ~cert ~key f =
    Switch.run @@ fun sw ->
    let processes = Eio.Stdenv.process_mgr env in
    let output, input = Eio.Process.pipe ~sw processes in
    let server = Eio.Process.spawn ~sw processes ~stdout:input [ node (); "-e"; script; cert; key ] in
    Eio.Flow.close input;
    Fun.protect
        ~finally:(fun () -> Eio.Process.signal server Sys.sigkill)
        (fun () ->
            let port = Eio.Buf_read.line (Eio.Buf_read.of_flow ~max_size:64 output) in
            f (Printf.sprintf "https://127.0.0.1:%s" port))
