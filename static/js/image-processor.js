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
    
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = function(e) {
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
                    
                    // Convert the canvas to a Blob
                    canvas.toBlob(function(blob) {
                        resolve(blob);
                    }, 'image/jpeg', 0.85);
                } catch (err) {
                    reject(err);
                }
            };
            img.onerror = function() {
                reject(new Error('Failed to load image'));
            };
            img.src = e.target.result;
        };
        reader.onerror = function() {
            reject(new Error('Failed to read file'));
        };
        reader.readAsDataURL(imageFile);
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
