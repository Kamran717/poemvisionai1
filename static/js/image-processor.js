// This file contains utility functions for client-side image processing

/**
 * Resize an image to a maximum width and height while maintaining aspect ratio
 * @param {HTMLImageElement} image - The image element to resize
 * @param {number} maxWidth - The maximum width of the resized image
 * @param {number} maxHeight - The maximum height of the resized image
 * @returns {Object} The resized dimensions { width, height }
 */
function calculateResizedDimensions(image, maxWidth, maxHeight) {
    let width = image.width;
    let height = image.height;
    
    // Calculate the scaling factor
    if (width > maxWidth || height > maxHeight) {
        const widthRatio = maxWidth / width;
        const heightRatio = maxHeight / height;
        const ratio = Math.min(widthRatio, heightRatio);
        
        width = Math.floor(width * ratio);
        height = Math.floor(height * ratio);
    }
    
    return { width, height };
}

/**
 * Create a thumbnail preview of an image
 * @param {string} src - The source URL of the image
 * @param {number} maxWidth - The maximum width of the thumbnail
 * @param {number} maxHeight - The maximum height of the thumbnail
 * @returns {Promise<string>} A Promise that resolves to the data URL of the thumbnail
 */
function createThumbnail(src, maxWidth, maxHeight) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = function() {
            try {
                const { width, height } = calculateResizedDimensions(img, maxWidth, maxHeight);
                
                // Create a canvas to draw the resized image
                const canvas = document.createElement('canvas');
                canvas.width = width;
                canvas.height = height;
                
                // Draw the image on the canvas
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);
                
                // Convert the canvas to a data URL
                const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
                resolve(dataUrl);
            } catch (err) {
                reject(err);
            }
        };
        img.onerror = function() {
            reject(new Error('Failed to load image'));
        };
        img.src = src;
    });
}

/**
 * Convert a data URL to a Blob
 * @param {string} dataUrl - The data URL to convert
 * @returns {Blob} The resulting Blob object
 */
function dataUrlToBlob(dataUrl) {
    const parts = dataUrl.split(';base64,');
    const contentType = parts[0].split(':')[1];
    const raw = window.atob(parts[1]);
    const rawLength = raw.length;
    const uInt8Array = new Uint8Array(rawLength);
    
    for (let i = 0; i < rawLength; ++i) {
        uInt8Array[i] = raw.charCodeAt(i);
    }
    
    return new Blob([uInt8Array], { type: contentType });
}

/**
 * Convert a Blob to a data URL
 * @param {Blob} blob - The Blob to convert
 * @returns {Promise<string>} A Promise that resolves to the data URL
 */
function blobToDataUrl(blob) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = function(e) {
            resolve(e.target.result);
        };
        reader.onerror = function() {
            reject(new Error('Failed to convert blob to data URL'));
        };
        reader.readAsDataURL(blob);
    });
}

/**
 * Check if an image is too large and resize it if necessary
 * @param {File} imageFile - The image file to check
 * @param {number} maxWidth - The maximum width of the image
 * @param {number} maxHeight - The maximum height of the image
 * @param {number} maxFileSize - The maximum file size in bytes
 * @returns {Promise<File|Blob>} A Promise that resolves to the original file or a resized Blob
 */
function checkAndResizeImage(imageFile, maxWidth, maxHeight, maxFileSize) {
    // If the file is already small enough, return it as-is
    if (imageFile.size <= maxFileSize) {
        return Promise.resolve(imageFile);
    }
    
    console.log(`Resizing image. Original size: ${(imageFile.size / 1024 / 1024).toFixed(2)}MB`);
    
    return new Promise((resolve, reject) => {
        // Add timeout to prevent mobile browser freezes during processing
        setTimeout(() => {
            const reader = new FileReader();
            reader.onload = function(e) {
                const img = new Image();
                img.onload = function() {
                    try {
                        // Calculate dimensions - use smaller dimensions for mobile
                        const isMobile = window.innerWidth <= 768;
                        const mobileMaxWidth = Math.min(maxWidth, 1200);
                        const mobileMaxHeight = Math.min(maxHeight, 1200);
                        
                        const { width, height } = calculateResizedDimensions(
                            img, 
                            isMobile ? mobileMaxWidth : maxWidth, 
                            isMobile ? mobileMaxHeight : maxHeight
                        );
                        
                        console.log(`Resizing to: ${width}x${height}`);
                        
                        // Create a canvas to draw the resized image
                        const canvas = document.createElement('canvas');
                        canvas.width = width;
                        canvas.height = height;
                        
                        // Draw the image on the canvas
                        const ctx = canvas.getContext('2d');
                        ctx.drawImage(img, 0, 0, width, height);
                        
                        // Use lower quality on mobile to reduce file size further
                        const quality = isMobile ? 0.75 : 0.85;
                        
                        // Convert the canvas to a Blob
                        canvas.toBlob(function(blob) {
                            console.log(`Resized image size: ${(blob.size / 1024 / 1024).toFixed(2)}MB`);
                            resolve(blob);
                        }, 'image/jpeg', quality);
                    } catch (err) {
                        console.error('Error during image resize:', err);
                        reject(err);
                    }
                };
                img.onerror = function() {
                    console.error('Failed to load image');
                    reject(new Error('Failed to load image'));
                };
                img.src = e.target.result;
            };
            reader.onerror = function() {
                console.error('Failed to read file');
                reject(new Error('Failed to read file'));
            };
            reader.readAsDataURL(imageFile);
        }, 50); // Small delay to let the UI update
    });
}

// Export the functions if using modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        calculateResizedDimensions,
        createThumbnail,
        dataUrlToBlob,
        blobToDataUrl,
        checkAndResizeImage
    };
}

// Premium feature access handler
function handlePremiumAccess(featureName) {
    const userIsPremium = document.body.getAttribute('data-user-premium') === 'true';
    if (!userIsPremium) {
        showPremiumAlert(featureName);
        return false;
    }
    return true;
}

// Function to show premium alert when accessing premium features
function showPremiumAlert(featureName) {
    const premiumAlert = document.getElementById('premiumAlert');
    if (premiumAlert) {
        // Update the message if we have a specific feature name
        if (featureName) {
            const message = premiumAlert.querySelector('.alert-message');
            if (message) {
                message.textContent = `Upgrade to Premium to access ${featureName} and other premium features!`;
            }
        }

        premiumAlert.classList.remove('d-none');

        // Scroll to the alert for better visibility
        premiumAlert.scrollIntoView({ behavior: 'smooth', block: 'center' });

        // Add a temporary highlight effect
        premiumAlert.classList.add('highlight-alert');
        setTimeout(() => {
            premiumAlert.classList.remove('highlight-alert');
        }, 2000);
    }
}

