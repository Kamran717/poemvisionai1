/**
 * Poem Vision AI Admin Panel JavaScript
 */

// Initialize tooltips
document.addEventListener('DOMContentLoaded', function() {
    // Initialize all tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    });

    // Add current year to the footer
    const currentYearElement = document.getElementById('currentYear');
    if (currentYearElement) {
        currentYearElement.textContent = new Date().getFullYear();
    }

    // Setup confirm action buttons
    const confirmButtons = document.querySelectorAll('[data-confirm]');
    confirmButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            if (!confirm(this.dataset.confirm)) {
                e.preventDefault();
                return false;
            }
        });
    });

    // Add active class to sidebar based on current page
    const currentPage = window.location.pathname;
    const navLinks = document.querySelectorAll('.navbar-nav .nav-link');
    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPage) {
            link.classList.add('active');
        }
    });

    // Removed unused sidebar toggle code since we're using a top navbar design
    
    // Safe check for elements before adding classes
    function safeToggleClass(selector, className) {
        const element = document.querySelector(selector);
        if (element) {
            element.classList.toggle(className);
        }
    }
    
    // Add basic responsive check for mobile
    function checkScreenSize() {
        if (window.innerWidth < 768) {
            // Adjust layout for mobile if needed
        }
    }
    
    // Check on page load and resize
    checkScreenSize();
    window.addEventListener('resize', checkScreenSize);

    // Initialize datepickers if any exist
    const datepickers = document.querySelectorAll('.datepicker');
    if (datepickers.length) {
        datepickers.forEach(el => {
            // This assumes you're using a library for datepickers
            // If you decide to use one, uncomment and modify this
            // new Datepicker(el, { /* options */ });
        });
    }

    // Handle dismissible alerts auto-close
    const alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(alert => {
        setTimeout(() => {
            const closeButton = alert.querySelector('.btn-close');
            if (closeButton) {
                closeButton.click();
            }
        }, 5000); // Auto-close after 5 seconds
    });
});

/**
 * Format number as currency
 * @param {number} number The number to format
 * @param {string} currency The currency code
 * @returns {string} Formatted currency string
 */
function formatCurrency(number, currency = 'USD') {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency
    }).format(number);
}

/**
 * Format number with commas for thousands
 * @param {number} number The number to format
 * @returns {string} Formatted number string
 */
function formatNumber(number) {
    return new Intl.NumberFormat('en-US').format(number);
}

/**
 * Format date to ISO format (YYYY-MM-DD)
 * @param {Date} date The date to format
 * @returns {string} Formatted date string
 */
function formatDate(date) {
    return date.toISOString().split('T')[0];
}

/**
 * Get relative time string (e.g., "2 hours ago")
 * @param {string} dateString The date string
 * @returns {string} Relative time string
 */
function getRelativeTimeString(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const seconds = Math.floor((now - date) / 1000);
    
    let interval = Math.floor(seconds / 31536000);
    if (interval >= 1) {
        return interval + ' year' + (interval === 1 ? '' : 's') + ' ago';
    }
    
    interval = Math.floor(seconds / 2592000);
    if (interval >= 1) {
        return interval + ' month' + (interval === 1 ? '' : 's') + ' ago';
    }
    
    interval = Math.floor(seconds / 86400);
    if (interval >= 1) {
        return interval + ' day' + (interval === 1 ? '' : 's') + ' ago';
    }
    
    interval = Math.floor(seconds / 3600);
    if (interval >= 1) {
        return interval + ' hour' + (interval === 1 ? '' : 's') + ' ago';
    }
    
    interval = Math.floor(seconds / 60);
    if (interval >= 1) {
        return interval + ' minute' + (interval === 1 ? '' : 's') + ' ago';
    }
    
    return Math.floor(seconds) + ' second' + (Math.floor(seconds) === 1 ? '' : 's') + ' ago';
}