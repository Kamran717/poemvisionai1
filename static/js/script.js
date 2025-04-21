document.addEventListener('DOMContentLoaded', function() {
    // State management
    const state = {
        currentStep: 1,
        analysisId: null,
        selectedFrame: 'classic',
        selectedEmphasis: [],
        image: null,
        imageBase64: null,
        maxEmphasisCount: 10 // Maximum number of elements that can be selected for emphasis
    };

    handleMobileUpload();

    // DOM Elements
    const uploadArea = document.getElementById('uploadArea');
    const imageInput = document.getElementById('imageInput');
    const uploadedImage = document.getElementById('uploadedImage');
    const uploadedImageContainer = document.getElementById('uploadedImageContainer');
    const changeImageBtn = document.getElementById('changeImageBtn');
    const analyzeImageBtn = document.getElementById('analyzeImageBtn');
    const uploadError = document.getElementById('uploadError');
    const loadingAnalysis = document.getElementById('loadingAnalysis');
    
    const backToStep1Btn = document.getElementById('backToStep1Btn');
    const generatePoemBtn = document.getElementById('generatePoemBtn');
    const loadingPoem = document.getElementById('loadingPoem');
    
    const backToStep2Btn = document.getElementById('backToStep2Btn');
    const createFinalBtn = document.getElementById('createFinalBtn');
    const loadingFinal = document.getElementById('loadingFinal');
    
    const startOverBtn = document.getElementById('startOverBtn');
    const downloadBtn = document.getElementById('downloadBtn');
    const regeneratePoemBtn = document.getElementById('regeneratePoemBtn');
    
    const step2Image = document.getElementById('step2Image');
    const poemStepImage = document.getElementById('poemStepImage');
    const generatedPoem = document.getElementById('generatedPoem');
    const finalCreation = document.getElementById('finalCreation');
    
    const frameOptions = document.querySelectorAll('.frame-option');
    
    const poemTypeSelect = document.getElementById('poemTypeSelect');
    const emphasisOptions = document.getElementById('emphasisOptions');

    // Navigation between steps
    function goToStep(step) {
        state.currentStep = step;
        
        // Handle tab activation
        document.querySelectorAll('#poemGeneratorTabs .nav-link').forEach((tab, index) => {
            if (index+1 < step) {
                tab.classList.remove('active', 'disabled');
            } else if (index+1 === step) {
                tab.classList.remove('disabled');
                tab.classList.add('active');
            } else {
                tab.classList.add('disabled');
                tab.classList.remove('active');
            }
        });
        
        // Activate the correct tab pane
        const tabId = `step${step}`;
        const tabPanes = document.querySelectorAll('.tab-pane');
        tabPanes.forEach(pane => {
            pane.classList.remove('show', 'active');
        });
        document.getElementById(tabId).classList.add('show', 'active');
    }

    // Handle image upload via drag and drop
    uploadArea.addEventListener('dragover', function(e) {
        e.preventDefault();
        uploadArea.classList.add('dragover');
    });

    uploadArea.addEventListener('dragleave', function() {
        uploadArea.classList.remove('dragover');
    });

    uploadArea.addEventListener('drop', function(e) {
        e.preventDefault();
        uploadArea.classList.remove('dragover');
        
        if (e.dataTransfer.files.length) {
            handleImageFile(e.dataTransfer.files[0]);
        }
    });

    // Mobile camera input handling
    const takePhotoBtn = document.getElementById('takePhotoBtn');
    const cameraInput = document.createElement('input');
    cameraInput.type = 'file';
    cameraInput.accept = 'image/*';
    cameraInput.capture = 'environment';
    cameraInput.style.display = 'none';
    document.body.appendChild(cameraInput);
    
    // Add click handlers that won't bubble
    takePhotoBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        cameraInput.click();
    });
    
    const uploadButton = document.querySelector('label[for="imageInput"]');
    if (uploadButton) {
        uploadButton.addEventListener('click', function(e) {
            e.stopPropagation(); // Prevent the click from bubbling to uploadArea
        });
    }
    
    // Still allow clicking anywhere in the upload area (for desktop)
    uploadArea.addEventListener('click', function(e) {
        // Only trigger the file input click if the click wasn't on one of our buttons
        if (!e.target.closest('label[for="imageInput"]') && 
            !e.target.closest('#takePhotoBtn')) {
            imageInput.click();
        }
    });

    // Handle file selection from gallery
    imageInput.addEventListener('change', function() {
        if (this.files.length) {
            handleImageFile(this.files[0]);
        }
    });
    
    // Handle file capture from camera
    cameraInput.addEventListener('change', function() {
        if (this.files.length) {
            handleImageFile(this.files[0]);
        }
    });

    // Process the uploaded image file
    function handleImageFile(file) {
        // Reset any previous errors
        uploadError.classList.add('d-none');
        
        // Validate the file
        if (!file.type.match('image.*')) {
            showUploadError('Please upload an image file (JPEG, PNG, etc.)');
            return;
        }
        
        if (file.size > 5 * 1024 * 1024) { // 5MB limit
            showUploadError('Image size exceeds the 5MB limit. Please choose a smaller image.');
            return;
        }
        
        // Store the file for later use
        state.image = file;
        
        // Display the image preview
        const reader = new FileReader();
        reader.onload = function(e) {
            uploadedImage.src = e.target.result;
            state.imageBase64 = e.target.result;
            uploadArea.classList.add('d-none');
            uploadedImageContainer.classList.remove('d-none');
            analyzeImageBtn.disabled = false;
        };
        reader.onerror = function(err) {
            console.error("FileReader error:", err);
            showUploadError('Error reading the image file. Please try a different image or method.');
        };
        reader.readAsDataURL(file);
    }
    
    // Fallback for direct data URI handling (useful for some mobile browsers)
    function handleImageDataUri(dataUri) {
        // Reset any previous errors
        uploadError.classList.add('d-none');
        
        // Some validation on the data URI
        if (!dataUri.startsWith('data:image/')) {
            showUploadError('Invalid image format. Please upload a JPEG or PNG image.');
            return;
        }
        
        // Rough size estimation for data URI
        const estimatedSize = Math.ceil((dataUri.length * 3) / 4);
        if (estimatedSize > 5 * 1024 * 1024) { // 5MB limit
            showUploadError('Image size exceeds the 5MB limit. Please choose a smaller image.');
            return;
        }
        
        // Create a blob from the data URI for later use
        try {
            const arr = dataUri.split(',');
            const mime = arr[0].match(/:(.*?);/)[1];
            const bstr = atob(arr[1]);
            let n = bstr.length;
            const u8arr = new Uint8Array(n);
            
            while (n--) {
                u8arr[n] = bstr.charCodeAt(n);
            }
            
            state.image = new Blob([u8arr], { type: mime });
        } catch (e) {
            console.error("Error converting data URI to Blob:", e);
        }
        
        // Display the image preview
        uploadedImage.src = dataUri;
        state.imageBase64 = dataUri;
        uploadArea.classList.add('d-none');
        uploadedImageContainer.classList.remove('d-none');
        analyzeImageBtn.disabled = false;
    }

    // Display upload error message
    function showUploadError(message) {
        uploadError.textContent = message;
        uploadError.classList.remove('d-none');
    }

    // Change the uploaded image
    changeImageBtn.addEventListener('click', function() {
        uploadArea.classList.remove('d-none');
        uploadedImageContainer.classList.add('d-none');
        analyzeImageBtn.disabled = true;
        imageInput.value = '';
        state.image = null;
        state.imageBase64 = null;
    });

    // Analyze the uploaded image
    analyzeImageBtn.addEventListener('click', function() {
        if (!state.image && !state.imageBase64) {
            showUploadError('Please upload an image first.');
            return;
        }
        
        // Show loading indicator
        loadingAnalysis.classList.remove('d-none');
        analyzeImageBtn.disabled = true;
        
        let fetchOptions = {};
        
        // Try to use FormData if we have a Blob/File (more reliable)
        if (state.image instanceof Blob) {
            console.log("Sending image as FormData");
            const formData = new FormData();
            formData.append('image', state.image);
            
            fetchOptions = {
                method: 'POST',
                body: formData
            };
        } 
        // Fall back to JSON with base64 if we only have imageBase64 (for some mobile browsers)
        else if (state.imageBase64) {
            console.log("Sending image as base64 JSON");
            fetchOptions = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    image: state.imageBase64
                })
            };
        } else {
            showUploadError('Invalid image data. Please try uploading again.');
            loadingAnalysis.classList.add('d-none');
            analyzeImageBtn.disabled = false;
            return;
        }
        
        // Send the image to the server for analysis
        fetch('/analyze-image', fetchOptions)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error ${response.status}: ${response.statusText}`);
            }
            return response.json();
        })
        .then(data => {
            // Hide loading indicator
            loadingAnalysis.classList.add('d-none');
            
            if (data.error) {
                console.error('Server returned error:', data.error);
                showUploadError(data.error);
                analyzeImageBtn.disabled = false;
                return;
            }
            
            // Store the analysis ID
            state.analysisId = data.analysisId;
            
            // Check if results exist and are valid
            if (!data.results || typeof data.results !== 'object') {
                console.error('Invalid analysis results:', data.results);
                showUploadError('Failed to process image analysis results. Please try again.');
                analyzeImageBtn.disabled = false;
                return;
            }
            
            // Display the analysis results
            displayAnalysisResults(data.results);
            
            // Set the image for step 2
            if (step2Image) {
                step2Image.src = state.imageBase64;
            }
            
            // Move to the next step
            goToStep(2);
        })
        .catch(error => {
            console.error('Error analyzing image:', error);
            loadingAnalysis.classList.add('d-none');
            showUploadError('An error occurred while analyzing the image. Please try again. If this issue persists, try with a smaller image.');
            analyzeImageBtn.disabled = false;
        });
    });
        
    // Mobile-specific upload flow
    function handleMobileUpload() {
        const imageInput = document.getElementById('imageInput');
        const uploadedImageContainer = document.getElementById('uploadedImageContainer');
        const analyzeBtnMobile = document.getElementById('analyzeImageBtnMobile');
        const analyzeBtnMain = document.getElementById('analyzeImageBtn');

        if (!imageInput || !analyzeBtnMobile) return;

        // Independent click handler that fully replicates main button logic
        analyzeBtnMobile.addEventListener('click', function() {
            // First validate we have an image (same as main button)
            if (!state.image && !state.imageBase64) {
                showUploadError('Please upload an image first.');
                return;
            }

            // Show loading indicator (same as main button)
            loadingAnalysis.classList.remove('d-none');
            analyzeBtnMobile.disabled = true;
            if (analyzeBtnMain) analyzeBtnMain.disabled = true; 

            // Prepare fetch options (same as main button)
            let fetchOptions = {};

            if (state.image instanceof Blob) {
                console.log("Mobile: Sending image as FormData");
                const formData = new FormData();
                formData.append('image', state.image);
                fetchOptions = {
                    method: 'POST',
                    body: formData
                };
            } 
            else if (state.imageBase64) {
                console.log("Mobile: Sending image as base64 JSON");
                fetchOptions = {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        image: state.imageBase64
                    })
                };
            } else {
                showUploadError('Invalid image data. Please try uploading again.');
                loadingAnalysis.classList.add('d-none');
                analyzeBtnMobile.disabled = false;
                if (analyzeBtnMain) analyzeBtnMain.disabled = false;
                return;
            }

            // Make the API request (same endpoint as desktop)
            fetch('/analyze-image', fetchOptions)
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`HTTP error ${response.status}: ${response.statusText}`);
                    }
                    return response.json();
                })
                .then(data => {
                    // Hide loading indicator
                    loadingAnalysis.classList.add('d-none');
                    analyzeBtnMobile.disabled = false;
                    if (analyzeBtnMain) analyzeBtnMain.disabled = false;

                    if (data.error) {
                        console.error('Server returned error:', data.error);
                        showUploadError(data.error);
                        return;
                    }

                    // Update state (critical - same as main button)
                    state.analysisId = data.analysisId;

                    if (!data.results || typeof data.results !== 'object') {
                        console.error('Invalid analysis results:', data.results);
                        showUploadError('Failed to process image analysis results. Please try again.');
                        return;
                    }

                    // Display results (same function as main button uses)
                    displayAnalysisResults(data.results);

                    // Update step 2 image
                    if (step2Image) {
                        step2Image.src = state.imageBase64;
                    }

                    // Navigate to next step
                    goToStep(2);
                })
                .catch(error => {
                    console.error('Mobile analysis error:', error);
                    loadingAnalysis.classList.add('d-none');
                    analyzeBtnMobile.disabled = false;
                    if (analyzeBtnMain) analyzeBtnMain.disabled = false;
                    showUploadError('An error occurred while analyzing the image. Please try again. If this issue persists, try with a smaller image.');
                });
        });

        // Show/hide mobile UI on file selection
        imageInput.addEventListener('change', function() {
            if (window.innerWidth < 768) {
                uploadedImageContainer.classList.remove('d-none');
            }
        });
    }
    

    // Display the analysis results and populate emphasis options
    function displayAnalysisResults(results) {
        // Display labels
        const detectedLabels = document.getElementById('detectedLabels');
        detectedLabels.innerHTML = '';
        
        // Clear the emphasis options before adding new ones
        emphasisOptions.innerHTML = '';

        // Keep track of all emphasis elements for visibility management
        const allEmphasisElements = [];
        let visibleElementsCount = 0;
        let totalElementsCount = 0;
        
        // Set max emphasis count for this session (limit to 4)
        state.maxEmphasisCount = 4;

        if (results.labels && results.labels.length > 0) {
            results.labels.forEach((label, index) => {
                const badge = document.createElement('span');
                badge.classList.add('badge', 'bg-secondary', 'me-2', 'mb-2', 'element-badge');
                badge.setAttribute('data-element', label.description);
                badge.textContent = `${label.description} (${label.score}%)`;
                detectedLabels.appendChild(badge);
                
                // Add to emphasis options
                const option = document.createElement('div');
                option.classList.add('form-check', 'form-check-inline', 'emphasis-element');
                
                // Initially show only the first 4 elements
                if (index >= 4) {
                    option.classList.add('emphasis-element-hidden');
                } else {
                    visibleElementsCount++;
                }
                
                option.innerHTML = `
                    <input class="form-check-input emphasis-checkbox" type="checkbox" value="${label.description}" id="emphasis_${label.description.replace(/\s+/g, '_')}">
                    <label class="form-check-label" for="emphasis_${label.description.replace(/\s+/g, '_')}">${label.description}</label>
                `;
                emphasisOptions.appendChild(option);
                allEmphasisElements.push(option);
                totalElementsCount++;
            });
        } else {
            detectedLabels.textContent = 'No labels detected.';
        }
        
        // Display objects
        const detectedObjects = document.getElementById('detectedObjects');
        detectedObjects.innerHTML = '';
        if (results.objects && results.objects.length > 0) {
            // Track person detection with confidence scores
            const personObjects = results.objects.filter(obj => obj.name === 'Person');
            const highConfidencePersons = personObjects.filter(obj => obj.score > 70);
            const mediumConfidencePersons = personObjects.filter(obj => obj.score >= 50 && obj.score <= 70);
            
            // Calculate a reasonable person count (avoiding duplicates)
            let personCount = highConfidencePersons.length;
            // Add medium confidence person objects more conservatively
            if (mediumConfidencePersons.length > 0) {
                personCount += Math.min(1, Math.floor(mediumConfidencePersons.length / 2));
            }
            
            // Check face detection to help confirm person count
            const faceCount = results.faces ? results.faces.length : 0;
            
            // Only if we have both face detection and object detection, use the more reliable count
            if (faceCount > 0) {
                // Use face count as a guide, but don't exceed it dramatically
                personCount = Math.min(personCount, faceCount + 1);
            }
            
            // Display each object
            results.objects.forEach(obj => {
                const badge = document.createElement('span');
                badge.classList.add('badge', 'bg-info', 'text-dark', 'me-2', 'mb-2', 'element-badge');
                badge.setAttribute('data-element', obj.name);
                badge.textContent = `${obj.name} (${obj.score}%)`;
                detectedObjects.appendChild(badge);
                
                // Add all objects to emphasis options equally
                const option = document.createElement('div');
                option.classList.add('form-check', 'form-check-inline', 'emphasis-element');
                
                // Add hidden class based on visible elements count
                if (document.querySelectorAll('.emphasis-element:not(.emphasis-element-hidden)').length >= 4) {
                    option.classList.add('emphasis-element-hidden');
                } else {
                    visibleElementsCount++;
                }
                
                option.innerHTML = `
                    <input class="form-check-input emphasis-checkbox" type="checkbox" value="${obj.name}" id="emphasis_${obj.name.replace(/\s+/g, '_')}">
                    <label class="form-check-label" for="emphasis_${obj.name.replace(/\s+/g, '_')}">${obj.name}</label>
                `;
                emphasisOptions.appendChild(option);
                allEmphasisElements.push(option);
            });
            
            // If people were detected, show a simplified note about the count
            if (personCount > 0) {
                const personNote = document.createElement('div');
                personNote.classList.add('mt-2', 'mb-2', 'small', 'text-info');
                
                if (personCount === 1) {
                    personNote.innerHTML = '<strong>Note:</strong> One person detected in the image.';
                } else {
                    personNote.innerHTML = `<strong>Note:</strong> ${personCount} people detected in the image.`;
                }
                
                detectedObjects.appendChild(personNote);
            }
        } else {
            detectedObjects.textContent = 'No objects detected.';
        }
        
        // Display faces
        const detectedFaces = document.getElementById('detectedFaces');
        detectedFaces.innerHTML = '';
        if (results.faces && results.faces.length > 0) {
            const emotions = [];
            results.faces.forEach(face => {
                for (const [emotion, likelihood] of Object.entries(face)) {
                    if (['joy', 'sorrow', 'anger', 'surprise'].includes(emotion) && 
                        ['LIKELY', 'VERY_LIKELY'].includes(likelihood)) {
                        emotions.push(emotion);
                    }
                }
            });
            
            if (emotions.length > 0) {
                const faceText = `${results.faces.length} ${results.faces.length === 1 ? 'face' : 'faces'} detected with emotions: `;
                const emotionsSpan = document.createElement('span');
                emotionsSpan.textContent = faceText;
                detectedFaces.appendChild(emotionsSpan);
                
                emotions.forEach(emotion => {
                    const badge = document.createElement('span');
                    badge.classList.add('badge', 'bg-warning', 'text-dark', 'me-2', 'mb-2', 'element-badge');
                    badge.setAttribute('data-element', emotion);
                    badge.textContent = emotion;
                    detectedFaces.appendChild(badge);
                    
                    // Add to emphasis options
                    const option = document.createElement('div');
                    option.classList.add('form-check', 'form-check-inline', 'emphasis-element');
                    
                    // Add hidden class based on visible elements count
                    if (document.querySelectorAll('.emphasis-element:not(.emphasis-element-hidden)').length >= 4) {
                        option.classList.add('emphasis-element-hidden');
                    } else {
                        visibleElementsCount++;
                    }
                    
                    option.innerHTML = `
                        <input class="form-check-input emphasis-checkbox" type="checkbox" value="${emotion}" id="emphasis_${emotion}">
                        <label class="form-check-label" for="emphasis_${emotion}">${emotion.charAt(0).toUpperCase() + emotion.slice(1)}</label>
                    `;
                    emphasisOptions.appendChild(option);
                    allEmphasisElements.push(option);
                });
            } else {
                detectedFaces.textContent = `${results.faces.length} ${results.faces.length === 1 ? 'face' : 'faces'} detected.`;
            }
        } else {
            detectedFaces.textContent = 'No faces detected.';
        }
        
        // Display landmarks
        const detectedLandmarks = document.getElementById('detectedLandmarks');
        detectedLandmarks.innerHTML = '';
        if (results.landmarks && results.landmarks.length > 0) {
            results.landmarks.forEach(landmark => {
                const badge = document.createElement('span');
                badge.classList.add('badge', 'bg-success', 'me-2', 'mb-2', 'element-badge');
                badge.setAttribute('data-element', landmark.description);
                badge.textContent = `${landmark.description} (${landmark.score}%)`;
                detectedLandmarks.appendChild(badge);
                
                // Add to emphasis options
                const option = document.createElement('div');
                option.classList.add('form-check', 'form-check-inline', 'emphasis-element');
                
                // Add hidden class based on visible elements count
                if (document.querySelectorAll('.emphasis-element:not(.emphasis-element-hidden)').length >= 4) {
                    option.classList.add('emphasis-element-hidden');
                } else {
                    visibleElementsCount++;
                }
                
                option.innerHTML = `
                    <input class="form-check-input emphasis-checkbox" type="checkbox" value="${landmark.description}" id="emphasis_${landmark.description.replace(/\s+/g, '_')}">
                    <label class="form-check-label" for="emphasis_${landmark.description.replace(/\s+/g, '_')}">${landmark.description}</label>
                `;
                emphasisOptions.appendChild(option);
                allEmphasisElements.push(option);
            });
        } else {
            detectedLandmarks.textContent = 'No landmarks detected.';
        }
        
        // Add click event for element badges to highlight/select
        document.querySelectorAll('.element-badge').forEach(badge => {
            badge.addEventListener('click', function() {
                const element = this.getAttribute('data-element');
                const checkbox = document.querySelector(`#emphasis_${element.replace(/\s+/g, '_')}`);
                if (checkbox) {
                    checkbox.checked = !checkbox.checked;
                    updateSelectedEmphasis();
                }
            });
        });
        
        // Add click event for checkboxes
        document.querySelectorAll('.emphasis-checkbox').forEach(checkbox => {
            checkbox.addEventListener('change', updateSelectedEmphasis);
        });
        
        // Add a "Show More" button if there are hidden elements
        const hiddenElements = document.querySelectorAll('.emphasis-element-hidden');
        if (hiddenElements.length > 0) {
            const showMoreBtn = document.createElement('button');
            showMoreBtn.textContent = 'Show All Elements';
            showMoreBtn.classList.add('show-more-btn', 'mt-2');
            showMoreBtn.setAttribute('id', 'showMoreEmphasisBtn');
            
            
            // Track if elements are currently shown or hidden
            let elementsShown = false;
            
            showMoreBtn.addEventListener('click', function() {
                event.preventDefault();
                
                if (!elementsShown) {
                    // Show all hidden elements
                    document.querySelectorAll('.emphasis-element-hidden').forEach(el => {
                        el.classList.remove('emphasis-element-hidden');
                    });
                    showMoreBtn.textContent = 'Show Fewer Elements';
                    elementsShown = true;
                } else {
                    // Hide elements again (except the first 4)
                    const allElements = Array.from(document.querySelectorAll('.emphasis-element'));
                    allElements.slice(4).forEach(el => {
                        el.classList.add('emphasis-element-hidden');
                    });
                    showMoreBtn.textContent = 'Show All Elements';
                    elementsShown = false;
                }
            });
            
            emphasisOptions.parentNode.insertBefore(showMoreBtn, emphasisOptions.nextSibling);
        }
        
        // Make sure our initial state includes any pre-checked boxes
        updateSelectedEmphasis();
    }

    // Update the selected emphasis elements
    function updateSelectedEmphasis() {
        // Get all checked checkboxes
        const checkedBoxes = [...document.querySelectorAll('.emphasis-checkbox:checked')];
        
        // Create or update the counter element if it doesn't exist
        let counterElement = document.getElementById('emphasis-counter');
        if (!counterElement) {
            counterElement = document.createElement('div');
            counterElement.id = 'emphasis-counter';
            counterElement.classList.add('mt-2', 'mb-3', 'small');
            const emphasisContainer = document.querySelector('.emphasis-container');
            if (emphasisContainer) {
                emphasisContainer.appendChild(counterElement);
            }
        }
        
        // If more than the maximum elements are selected, uncheck the last selected one
        if (checkedBoxes.length > state.maxEmphasisCount) {
            // Get the most recently changed checkbox (likely the last one checked)
            const lastChecked = checkedBoxes[checkedBoxes.length - 1];
            lastChecked.checked = false;
            
            // Remove the last one from our checked collection
            checkedBoxes.pop();
            
            // Show visual feedback (temporarily highlight the counter in red)
            counterElement.classList.add('text-danger', 'fw-bold');
            setTimeout(() => {
                counterElement.classList.remove('text-danger', 'fw-bold');
            }, 1500);
        }
        
        // Update the counter display
        const count = checkedBoxes.length;
        counterElement.textContent = `${count}/${state.maxEmphasisCount} elements selected`;
        
        // Update styles based on count
        if (count === state.maxEmphasisCount) {
            counterElement.classList.add('text-warning');
        } else {
            counterElement.classList.remove('text-warning');
        }
        
        // Update our state with the (limited) selection
        state.selectedEmphasis = checkedBoxes.map(checkbox => checkbox.value);
        
        // Update badge highlighting
        document.querySelectorAll('.element-badge').forEach(badge => {
            const element = badge.getAttribute('data-element');
            if (state.selectedEmphasis.includes(element)) {
                badge.classList.add('selected');
            } else {
                badge.classList.remove('selected');
            }
        });
        
        // Update the UI to show how many elements are selected
        const emphasisLabel = document.querySelector('label[for="emphasisOptions"]');
        if (emphasisLabel) {
            emphasisLabel.innerHTML = `Elements to Emphasize <small class="text-muted">(${state.selectedEmphasis.length}/${state.maxEmphasisCount} selected)</small>`;
        }
        
        // Initial update of the state when displayAnalysisResults is called
        // This ensures any pre-checked elements are properly included in state.selectedEmphasis
        
        // Log selected emphasis for debugging
        console.log("Selected emphasis elements:", state.selectedEmphasis);
    }

    // Create a separate function for poem generation
    function generatePoem(isRegeneration = false) {
        console.log('Generating poem - regeneration:', isRegeneration);
        console.log('Current analysisId:', state.analysisId);

        if (!state.analysisId) {
            console.error('Cannot generate poem - no analysisId in state');
            alert('Session expired. Please upload your image again.');
            goToStep(1);
            return;
        }
        
        

        // Show loading indicator
        loadingPoem.classList.remove('d-none');

        // Disable the appropriate button based on which one was clicked
        if (isRegeneration) {
            regeneratePoemBtn.disabled = true;
        } else {
            generatePoemBtn.disabled = true;
        }

        // Gather poem preferences
        const poemType = poemTypeSelect.value;
        const poemLength = poemLengthSelect.value;

        // Get structured custom prompt inputs
        const customName = document.getElementById('customName');
        const customPlace = document.getElementById('customPlace');
        const customEmotion = document.getElementById('customEmotion');
        const customAction = document.getElementById('customAction');
        const customPromptInput = document.getElementById('customPromptInput');
        const customPromptCategory = document.getElementById('customPromptCategory');

        // Build a structured prompt object
        const customPromptData = {
            category: customPromptCategory ? customPromptCategory.value : 'structured',
            name: customName ? customName.value.trim() : '',
            place: customPlace ? customPlace.value.trim() : '',
            emotion: customEmotion ? customEmotion.value : '',
            action: customAction ? customAction.value.trim() : '',
            additional: customPromptInput ? customPromptInput.value.trim() : ''
        };

        // Send the request to generate a poem
        fetch('/generate-poem', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                analysisId: state.analysisId,
                poemType: poemType,
                poemLength: poemLength,
                emphasis: state.selectedEmphasis,
                customPrompt: customPromptData,
                isRegeneration: isRegeneration
            })
        })
        .then(response => response.json())
        .then(data => {
            // Hide loading indicator
            loadingPoem.classList.add('d-none');

            // Re-enable the buttons
            generatePoemBtn.disabled = false;
            regeneratePoemBtn.disabled = false;
            if (data.analysisId) {
                state.analysisId = data.analysisId;
            }

            if (data.error) {
                alert(data.error);
                return;
            }

            // Display the generated poem
            generatedPoem.textContent = data.poem;

            // Copy the image to the poem step
            poemStepImage.src = uploadedImage.src;

            // Move to the next step - only if this isn't a regeneration
            if (!isRegeneration) {
                goToStep(3);
            }
        })
        .catch(error => {
            console.error('Error generating poem:', error);
            loadingPoem.classList.add('d-none');
            generatePoemBtn.disabled = false;
            regeneratePoemBtn.disabled = false;
            alert('An error occurred while generating the poem. Please try again.');
        });
    }

    // Generate the poem - initial generation
    generatePoemBtn.addEventListener('click', function() {
        generatePoem(false); // Not a regeneration
    });

    // Regenerate the poem
    regeneratePoemBtn.addEventListener('click', function() {
        generatePoem(true); // This is a regeneration
    });

    // Select a frame
    frameOptions.forEach(option => {
        option.addEventListener('click', function() {
            // Remove selection from all options
            frameOptions.forEach(o => o.classList.remove('selected'));
            
            // Add selection to the clicked option
            this.classList.add('selected');
            
            // Update the selected frame
            state.selectedFrame = this.getAttribute('data-frame');
        });
    });

    // Create the final image
    createFinalBtn.addEventListener('click', function() {
        if (!state.analysisId) {
            return;
        }
        
        // Show loading indicator
        loadingFinal.classList.remove('d-none');
        createFinalBtn.disabled = true;
        
        // Send the request to create the final image
        fetch('/create-final-image', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                analysisId: state.analysisId,
                //frameStyle: state.selectedFrame
            })
        })
        .then(response => response.json())
        .then(data => {
            // Hide loading indicator
            loadingFinal.classList.add('d-none');
            createFinalBtn.disabled = false;
            
            if (data.error) {
                alert(data.error);
                return;
            }
            
            // Display the final creation
            const finalImageSrc = `data:image/jpeg;base64,${data.finalImage}`;
            finalCreation.src = finalImageSrc;
            
            // Ensure proper orientation for mobile devices
            finalCreation.onload = function() {
                // Force the browser to respect the intended orientation
                finalCreation.style.width = 'auto';
                finalCreation.style.height = 'auto';
                finalCreation.style.maxWidth = '100%';
                
                // Apply special handling for mobile devices
                if (window.innerWidth <= 768) {
                    finalCreation.classList.add('mobile-display');
                }
            };
            
            // Set up the download button properly with correct attributes
            downloadBtn.href = finalImageSrc;
            downloadBtn.setAttribute('download', 'my-custom-poem.jpg');

            
            
            // Add event listener to handle download for browsers that don't support download attribute
            downloadBtn.addEventListener('click', function(e) {
                // For browsers that don't support the download attribute
                const isIE = !!window.MSInputMethodContext && !!document.documentMode;
                const isEdge = navigator.userAgent.indexOf("Edge") > -1;
                const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
                
                if (isIE || isEdge || isIOS) {
                    e.preventDefault();
                    
                    // Create a temporary link with download functionality
                    const tmpLink = document.createElement('a');
                    tmpLink.href = finalImageSrc;
                    tmpLink.download = 'my-custom-poem.jpg';
                    tmpLink.style.display = 'none';
                    document.body.appendChild(tmpLink);
                    
                    // Create a blob and download it
                    fetch(finalImageSrc)
                        .then(res => res.blob())
                        .then(blob => {
                            const url = window.URL.createObjectURL(blob);
                            tmpLink.href = url;
                            tmpLink.click();
                            window.URL.revokeObjectURL(url);
                            document.body.removeChild(tmpLink);
                        })
                        .catch(err => {
                            console.error('Error downloading image:', err);
                            alert('Could not download the image. Try right-clicking on the image and selecting "Save image as..."');
                        });
                }
            });
            
            // Also store the data for sharing
            state.finalImageSrc = finalImageSrc;
            if (data.shareCode) {
                console.log('Share code received:', data.shareCode);
                state.shareCode = data.shareCode;
                setupSharing(data.shareCode)
            } else {
                console.error('No share code received from server');
            }
            
            // Move to the next step
            goToStep(4);
        })
        .catch(error => {
            console.error('Error creating final image:', error);
            loadingFinal.classList.add('d-none');
            createFinalBtn.disabled = false;
            alert('An error occurred while creating the final image. Please try again.');
        });
    });

    document.getElementById('downloadBtn')?.addEventListener('click', function(e){
        // Check if user is logged in
        if (!this.hasAttribute('data-user-logged-in')) {
            e.preventDefault();
            showLoginPrompt();
            return false;
        }

        // Regular download logic for logged-in users
        const imageSrc = document.getElementById('finalCreation').src;
        const link = document.createElement('a');
        link.href = imageSrc;
        link.download = 'my-poem-creation.jpg';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        // Show thank you message
        showThankYouMessage();
    });

    // Function to show login prompt
    function showLoginPrompt() {
        // Create a Bootstrap modal for login prompt
        const modalHTML = `
        <div class="modal fade" id="loginPromptModal" tabindex="-1" aria-labelledby="loginPromptModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="loginPromptModalLabel">Login Required</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body text-center">
                        <div class="mb-4">
                            <i class="fas fa-user-lock fa-3x text-warning"></i>
                        </div>
                        <h5>Please login or create an account</h5>
                        <p class="text-muted">You need to be logged in to download and share your poem creations.</p>
                    </div>
                    <div class="modal-footer justify-content-center">
                        <a href="/login" class="btn btn-primary">
                            <i class="fas fa-sign-in-alt me-2"></i>Login
                        </a>
                        <a href="/signup" class="btn btn-success">
                            <i class="fas fa-user-plus me-2"></i>Sign Up
                        </a>
                    </div>
                </div>
            </div>
        </div>
        `;

        // Add modal to the body if it doesn't exist
        if (!document.getElementById('loginPromptModal')) {
            const modalContainer = document.createElement('div');
            modalContainer.innerHTML = modalHTML;
            document.body.appendChild(modalContainer);
        }

        // Show the modal using Bootstrap
        const loginModal = new bootstrap.Modal(document.getElementById('loginPromptModal'));
        loginModal.show();
    }

    // Store the original text content
    const originalHeadingHTML = document.querySelector('.h4.mb-3.text-muted.fw-normal').innerHTML;
    const originalParagraphText = document.querySelector('p.lead').textContent;

    // Function to show thank you message
    function showThankYouMessage() {
        const heading = document.querySelector('.h4.mb-3.text-muted.fw-normal');
        const leadParagraph = document.querySelector('p.lead');

        if (!heading || !leadParagraph) return;

        // Update the heading
        heading.innerHTML = '<span class="d-block">Thank you for Creating with Poem Vision AI!</span>';
        heading.classList.add('text-success', 'animate__animated', 'animate__fadeIn');

        // Update the paragraph
        leadParagraph.innerHTML = '<i class="fas fa-heart text-danger me-2"></i> Your poem has been crafted, framed and made personal - just like you imagined. Keep us close for the moments that matter. Birthdays, love notes, reflections, celebrations - whenever words need to shine, we are here. Save, share, or create again anytime. We are always one click away.';
        leadParagraph.classList.add('animate__animated', 'animate__fadeIn');

        // Scroll to the heading if needed
        heading.scrollIntoView({ behavior: 'smooth', block: 'center' });

        // Set a timeout to revert back to original text after some time
        setTimeout(() => {
            heading.classList.add('animate__fadeOut');
            leadParagraph.classList.add('animate__fadeOut');

            setTimeout(() => {
                heading.innerHTML = originalHeadingHTML;
                leadParagraph.innerHTML = originalParagraphText;

                heading.classList.remove('text-success', 'animate__animated', 'animate__fadeIn', 'animate__fadeOut');
                leadParagraph.classList.remove('animate__animated', 'animate__fadeIn', 'animate__fadeOut');
            }, 1000);
        }, 20000); 
    }

    // Navigation button event listeners
    backToStep1Btn.addEventListener('click', function() {
        goToStep(1);
    });

    backToStep2Btn.addEventListener('click', function() {
        // Make sure step2Image is updated when navigating back
        if (step2Image) {
            step2Image.src = poemStepImage.src;
        }
        goToStep(2);
    });

    startOverBtn.addEventListener('click', function() {
        // Reset the state
        state.analysisId = null;
        state.selectedFrame = 'classic';
        state.selectedEmphasis = [];
        
        // Reset the UI
        imageInput.value = '';
        uploadArea.classList.remove('d-none');
        uploadedImageContainer.classList.add('d-none');
        analyzeImageBtn.disabled = true;
        
        // Clear emphasis options
        emphasisOptions.innerHTML = '';
        
        // Go back to the first step
        goToStep(1);
    });
    
    // Select the first frame option by default
    frameOptions[0].classList.add('selected');
    
    // Sharing functionality
    const shareUrlInput = document.getElementById('shareUrlInput');
    const copyLinkBtn = document.getElementById('copyLinkBtn');
    const shareWhatsApp = document.getElementById('shareWhatsApp');
    const shareInstagram = document.getElementById('shareInstagram');
    const shareFacebook = document.getElementById('shareFacebook');
    const shareTikTok = document.getElementById('shareTikTok');
    const shareTwitter = document.getElementById('shareTwitter');
    const sharePinterest = document.getElementById('sharePinterest');
    const shareEmail = document.getElementById('shareEmail');
    
    // Custom prompt character counter and suggestion chips functionality
    const customPromptInput = document.getElementById('customPromptInput');
    const characterCounter = document.querySelector('.character-counter');
    const promptChips = document.querySelectorAll('.prompt-chip');
    
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Character counter functionality
    if (customPromptInput && characterCounter) {
        customPromptInput.addEventListener('input', function() {
            const currentLength = this.value.length;
            const maxLength = this.getAttribute('maxlength') || 300;
            characterCounter.textContent = `${currentLength}/${maxLength}`;
            
            // Add visual feedback when approaching the limit
            if (currentLength >= maxLength * 0.9) {
                characterCounter.classList.add('bg-danger');
                characterCounter.classList.remove('bg-dark', 'bg-warning');
            } else if (currentLength >= maxLength * 0.7) {
                characterCounter.classList.add('bg-warning');
                characterCounter.classList.remove('bg-dark', 'bg-danger');
            } else {
                characterCounter.classList.add('bg-dark');
                characterCounter.classList.remove('bg-warning', 'bg-danger');
            }
        });
        
        // Initialize the counter
        customPromptInput.dispatchEvent(new Event('input'));
    }
    
    // Suggestion chips functionality
    if (promptChips.length) {
        promptChips.forEach(chip => {
            chip.addEventListener('click', function() {
                const category = this.getAttribute('data-category');
                const promptText = this.getAttribute('data-prompt');
                
                // Select the corresponding category
                const categorySelect = document.getElementById('customPromptCategory');
                if (categorySelect) {
                    categorySelect.value = category;
                }
                
                // Add the suggestion to the input
                if (customPromptInput) {
                    // If there's already text, add a comma unless it ends with one
                    if (customPromptInput.value.trim()) {
                        if (!customPromptInput.value.trim().endsWith(',')) {
                            customPromptInput.value += ', ';
                        } else {
                            customPromptInput.value += ' ';
                        }
                    }
                    
                    // Add the suggestion
                    customPromptInput.value += promptText;
                    
                    // Trigger the character counter update
                    customPromptInput.dispatchEvent(new Event('input'));
                    
                    // Focus the input so user can continue typing
                    customPromptInput.focus();
                }
            });
        });
    }
    
    // Function to handle sharing when the creation is complete
    function setupSharing(shareCode) {
        const shareUrl = `${window.location.origin}/shared/${shareCode}`;

        // Set the share URL in the input field
        const shareUrlInput = document.getElementById('shareUrlInput');
        if (shareUrlInput) {
            shareUrlInput.value = shareUrl;
        }

        // Universal login check and thank you message
        function handleShareAction(e, callback) {
            if (!this.hasAttribute('data-user-logged-in')) {
                e.preventDefault();
                showLoginPrompt();
                return false;
            }

            // Execute the share action if provided
            if (typeof callback === 'function') {
                callback();
            }

            showThankYouMessage();
            return true;
        }

        // Copy Link Button - Modern Approach with Fallback
        document.getElementById('copyLinkBtn')?.addEventListener('click', async function(e) {
            if (!handleShareAction.call(this, e)) return;

            try {
                // Modern clipboard API
                await navigator.clipboard.writeText(shareUrl);

                // Visual feedback
                const originalHTML = this.innerHTML;
                this.innerHTML = '<i class="fas fa-check"></i>';
                this.classList.add('btn-success');
                this.classList.remove('btn-outline-secondary');

                // Revert after 2 seconds
                setTimeout(() => {
                    this.innerHTML = originalHTML;
                    this.classList.remove('btn-success');
                    this.classList.add('btn-outline-secondary');
                }, 2000);
            } catch (err) {
                // Fallback for older browsers
                shareUrlInput.select();
                document.execCommand('copy');

                // Visual feedback for fallback
                const originalHTML = this.innerHTML;
                this.innerHTML = '<i class="fas fa-check"></i>';
                setTimeout(() => {
                    this.innerHTML = originalHTML;
                }, 2000);
            }
        });

        // Social Share Buttons
        const shareButtons = {
            shareWhatsApp: () => {
                window.open(`https://wa.me/?text=${encodeURIComponent('Check out my poem: ' + shareUrl)}`, '_blank');
            },
            shareInstagram: () => {
                shareUrlInput.select();
                document.execCommand('copy');
                alert('Instagram requires manual sharing. We\'ve copied the link to your clipboard.');
                window.open('https://www.instagram.com/', '_blank');
            },
            shareFacebook: () => {
                window.open(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(shareUrl)}`, '_blank');
            },
            shareTikTok: () => {
                shareUrlInput.select();
                document.execCommand('copy');
                alert('TikTok requires manual sharing. We\'ve copied the link to your clipboard.');
                window.open('https://www.tiktok.com/', '_blank');
            },
            shareTwitter: () => {
                window.open(`https://twitter.com/intent/tweet?text=${encodeURIComponent('Check out my poem:')}&url=${encodeURIComponent(shareUrl)}`, '_blank');
            },
            sharePinterest: () => {
                const imageUrl = document.getElementById('finalCreation').src;
                window.open(`https://pinterest.com/pin/create/button/?url=${encodeURIComponent(shareUrl)}&media=${encodeURIComponent(imageUrl)}`, '_blank');
            },
            shareEmail: () => {
                window.open(`mailto:?subject=Check out my poem&body=I created this with Poem Vision AI: ${encodeURIComponent(shareUrl)}`);
            }
        };

        // Attach event listeners to all share buttons
        Object.keys(shareButtons).forEach(buttonId => {
            document.getElementById(buttonId)?.addEventListener('click', function(e) {
                handleShareAction.call(this, e, shareButtons[buttonId]);
            });
        });
    }
    
    // Watch for changes to the state's shareCode
    Object.defineProperty(state, 'shareCode', {
        set: function(newShareCode) {
            this._shareCode = newShareCode;
            if (newShareCode) {
                setupSharing(newShareCode);
            }
        },
        get: function() {
            return this._shareCode;
        }
    });

});
