document.getElementById('helloBtn').addEventListener('click', function() {
    const greeting = document.getElementById('greetingMessage');
    greeting.textContent = 'Hello, world! Thanks for visiting my static site. The JS is working!';
});