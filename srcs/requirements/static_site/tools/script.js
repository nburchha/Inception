document.addEventListener("DOMContentLoaded", () => {
    const helloBtn = document.getElementById('helloBtn');
    const greetingMsg = document.getElementById('greetingMessage');

    if (helloBtn && greetingMsg) {
        helloBtn.addEventListener('click', function() {
            greetingMsg.textContent = 'Hello! Welcome to my Cloud Native portfolio. Infrastructure is ready.';
            greetingMsg.classList.add('visible');

            // Optional: reset after a few seconds
            setTimeout(() => {
                greetingMsg.classList.remove('visible');
                setTimeout(() => {
                    greetingMsg.textContent = '';
                }, 500); // Wait for transition
            }, 3500);
        });
    }

    // Optional: Add basic scroll animation for cards
    const cards = document.querySelectorAll('.skill-card');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = 1;
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });

    cards.forEach(card => {
        card.style.opacity = 0;
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
});
