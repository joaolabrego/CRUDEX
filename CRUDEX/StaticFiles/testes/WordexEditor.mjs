// dentro de _wireToolbar()
const bar = document.querySelector('[data-toolbar="text"]');

bar.addEventListener("click", (e) => {
  const btn = e.target.closest("button");
  if (!btn) return;

  const cmd = btn.dataset.cmd;
  if (!cmd) return;

  e.preventDefault();
  applyCmd(cmd);
});
