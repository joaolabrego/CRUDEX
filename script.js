function runLongTask() {
  const loader = document.getElementById('loader');
  loader.classList.remove('hidden'); // Mostrar o spinner

  // Usando setTimeout para permitir que a UI seja atualizada antes de iniciar a tarefa pesada
  setTimeout(() => {
    performLongSyncOperation(); // Substitua isso pela sua função real
    loader.classList.add('hidden'); // Esconder o spinner após a conclusão
  }, 0);
}

function performLongSyncOperation() {
  // Simulando uma tarefa longa
  const startTime = new Date().getTime();
  while (new Date().getTime() - startTime < 10000); // Bloqueia a UI por 3 segundos
}
