function runLongTask() {
    const loader = document.getElementById('loader');
    loader.classList.remove('hidden'); // Mostrar o spinner

    setTimeout(() => {
        alert("Clique-me!"); // Substitua isso pela sua função real
        loader.classList.add('hidden'); // Esconder o spinner após a conclusão
    }, 1)
}