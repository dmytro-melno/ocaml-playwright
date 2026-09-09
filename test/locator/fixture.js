// Shared deterministic fixture for OCaml and the pinned JavaScript client.
// It is evaluated as a function, avoiding HTML parser CR/attribute normalization.
() => {
  document.body.innerHTML = `<style>
    body { margin:0 } #offscreen { position:absolute; top:2500px }
    #hidden { display:none }
    iframe { position:absolute; left:100px; top:200px; border:0; width:300px; height:120px }
  </style>
  <section id="buttons"><button id="one">Save</button><button id="two">Cancel</button></section>
  <input class="text"><input class="text">
  <input class="check" type="checkbox"><input class="check" type="checkbox">
  <input class="file" type="file"><input class="file" type="file">
  <select><option>A</option></select><select><option>B</option></select>
  <article id="article"><span id="words">Alpha \n\t Beta</span><b id="special"></b></article>
  <article id="other">Other</article>
  <input id="named"><label for="named" id="label"></label><img id="image">
  <button id="hidden">hidden</button><button id="offscreen">offscreen</button>
  <iframe></iframe>`;
  window.special = 'Quote " slash \\ newline\n tab\t carriage\r Ω雪';
  const special = document.querySelector('#special');
  special.textContent = window.special;
  special.setAttribute('data-testid', window.special);
  special.setAttribute('data-qa', window.special);
  special.setAttribute('data-next', window.special);
  document.querySelector('#label').textContent = window.special;
  document.querySelector('#named').setAttribute('placeholder', window.special);
  document.querySelector('#named').setAttribute('aria-label', window.special);
  document.querySelector('#image').setAttribute('alt', window.special);
  document.querySelector('#image').setAttribute('title', window.special);
  for (const button of document.querySelectorAll('#buttons button'))
    button.onclick = () => window.clicked = button.id;
  window.clicked = null;
}
