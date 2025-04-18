/**
 * Membership and premium features handling for Poem Vision AI
 */

// Cache for feature access permissions
const accessCache = {
    poemTypes: {},
    frames: {},
    poemLengths: {}
};

// Indicate whether user is premium
let isPremium = false;

/**
 * Initialize the membership features
 */
async function initMembership() {
    console.log('Initializing membership features...');
    try {
        // Use the existing endpoint that returns premium status
        const response = await fetch('/api/available-poem-types', {
            credentials: 'include' 
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        isPremium = data.is_premium || false;
        console.log('Premium status initialized:', isPremium);

        // Now proceed with initialization
        await fetchAvailablePoemTypes();
        await fetchAvailableFrames();
        await fetchAvailablePoemLengths();
        setupUpgradePrompts();
    } catch (error) {
        console.error('Membership init error:', error);
        // Fallback to non-premium if there's an error
        isPremium = false;
        await fetchAvailablePoemTypes();
        await fetchAvailableFrames();
        await fetchAvailablePoemLengths();
        
    }
}

// fetch and update poem lengths
async function fetchAvailablePoemLengths() {
    try {
        const response = await fetch('/api/available-poem-lengths', {
            credentials: 'include'
        });

        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

        const data = await response.json();
        if (data.poem_lengths) {
            updatePoemLengthDropdown(data.poem_lengths);
        }
    } catch (error) {
        console.error('Error fetching poem lengths:', error);
        updatePoemLengthDropdown([]);
    }
}

function updatePoemLengthDropdown(lengths) {
    const select = document.getElementById('poemLengthSelect');
    if (!select) return;

    select.innerHTML = '';

    lengths.forEach(length => {
        const option = document.createElement('option');
        option.value = length.id;
        option.textContent = length.name;

        if (!length.has_access) {
            option.textContent += ' 🔒';
            option.classList.add('premium-option');
            option.disabled = true;
        }

        // Cache access status
        accessCache.poemLengths[length.id] = length.has_access;

        select.appendChild(option);
    });

    // Set default to first available length
    const availableLength = lengths.find(l => l.has_access);
    if (availableLength) {
        select.value = availableLength.id;
    }
}


/**
 * Fetch the available poem types for the current user
 */
async function fetchAvailablePoemTypes() {
    console.log('Fetching available poem types...');
    try {
        const response = await fetch('/api/available-poem-types', {
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        if (data.poem_types) {
            isPremium = data.is_premium; // Update from response
            updatePoemTypeDropdown(data.poem_types);
        }
    } catch (error) {
        console.error('Error fetching poem types:', error);
        // Fallback to free types only
        updatePoemTypeDropdown([]);
    }
}

/**
 * Fetch the available frames for the current user
 */
async function fetchAvailableFrames() {
    try {
        const response = await fetch('/api/available-frames', {
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        if (data.frames) {
            isPremium = data.is_premium; // Update from response
            updateFrameOptions(data.frames);
        }
    } catch (error) {
        console.error('Error fetching frames:', error);
        // Fallback to free frames only
        updateFrameOptions([]);
    }
}

/**
 * Check if a user has access to a specific feature
 * @param {string} featureType - The type of feature ('poem_type' or 'frame')
 * @param {string} featureId - The ID of the feature
 * @returns {Promise<boolean>} Promise resolving to access status
 */
async function checkFeatureAccess(featureType, featureId) {
    // Check cache first
    if (featureType === 'poem_type' && accessCache.poemTypes.hasOwnProperty(featureId)) {
        return accessCache.poemTypes[featureId];
    }

    if (featureType === 'frame' && accessCache.frames.hasOwnProperty(featureId)) {
        return accessCache.frames[featureId];
    }

    if (featureType === 'poem_length' && accessCache.poemLengths.hasOwnProperty(featureId)) {
        return Promise.resolve(accessCache.poemLengths[featureId]);
    }

    try {
        const response = await fetch('/api/check-access', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                type: featureType,
                id: featureId
            }),
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        // Update cache
        if (featureType === 'poem_type') {
            accessCache.poemTypes[featureId] = data.has_access;
        } else if (featureType === 'frame') {
            accessCache.frames[featureId] = data.has_access;
        }  else if (featureType === 'poem_length') {
            accessCache.poemLengths[featureId] = data.has_access;
        }

        // Update premium status
        isPremium = data.is_premium;

        return data.has_access;
    } catch (error) {
        console.error('Error checking feature access:', error);
        return false; // Default to no access on error
    }
}

/**
 * Update the poem type dropdown with available options based on membership
 * @param {Array} poemTypes - Array of poem types with availability flags
 */
function updatePoemTypeDropdown(poemTypes) {
    const poemTypeSelect = document.getElementById('poemTypeSelect');
    if (!poemTypeSelect) return;

    console.log('Updating poem dropdown. Current premium:', isPremium);

    // Clear any existing premium legend
    const existingLegend = poemTypeSelect.parentNode.querySelector('.premium-legend');
    if (existingLegend) {
        existingLegend.remove();
    }

    // Remember current selection
    const currentSelection = poemTypeSelect.value;
    poemTypeSelect.innerHTML = '';

    // Create optgroups
    const standardGroup = document.createElement('optgroup');
    standardGroup.label = "Standard Poems";


    const religiousGroup = document.createElement('optgroup');
    religiousGroup.label = "Religious Poems";

    const funGroup = document.createElement('optgroup');
    funGroup.label = "Fun Formats";

    const famousPoetsGroup = document.createElement('optgroup');
    famousPoetsGroup.label = "Famous Poets";

    const flirtyFunGroup = document.createElement('optgroup');
    flirtyFunGroup.label = "Flirty & Fun";

    const congratulationsGroup = document.createElement('optgroup');
    congratulationsGroup.label = "Congratulations";

    const holidaysGroup = document.createElement('optgroup');
    holidaysGroup.label = "Holidays";

    const musicGroup = document.createElement('optgroup');
    musicGroup.label = "Music Inspired";

    const artistGroup = document.createElement('optgroup');
    artistGroup.label = "Artist Inspired";


    const classicGroup = document.createElement('optgroup');
    classicGroup.label = "Classical Forms";

    const tribulationsGroup = document.createElement('optgroup');
    tribulationsGroup.label = "Tribulations";

    // Define poem types categorization
    const poemCategories = {
        standard: ['free verse', 'love', 'funny', 'inspirational', 'angry', 'extreme', 'holiday', 'birthday', 'anniversary', 'nature', 'friendship'],
        religious: ['religious-islam', 'religious-christian', 'religious-judaism', 'religious-general'],
        fun: ['twinkle', 'roses', 'knock-knock','hickory dickory dock','nursery-rhymes'],
        famousPoets: ['william-shakespeare', 'dante-alighieri', 'rumi', 'emily-dickinson', 'robert-frost', 'langston-hughes', 'sylvia-plath', 'pablo-neruda', 'walt-whitman', 'edgar-allan-poe'],
        flirtyFun: ['pick-up', 'roast-you', 'first-date-feel', 'love-at-first-sight'],
        congratulations: ['new-job', 'graduation', 'wedding', 'engagement', 'new-baby', 'promotion', 'new-home', 'new-car', 'new-pet', 'first-day-of-school', 'retirement'],
        holidays: ['new-year', 'valentines-day', 'ramadan', 'easter', 'mother-day', 'father-day','independence-day', 'halloween', 'thanksgiving', 'christmas','hanukkah','diwali','new-year-eve'],
        music: ['rap/hiphop', 'country', 'rock', 'pop', 'jazz'],
        artist: ['eminem','taylor-swift','drake','50cent','lil-wayne','doja-cat','nicki-minaj','kendrick-lamar','j. cole','elvis-presley', 'tupac','biggie-smalls','buddy-holly','luis-armstrong'],
        classic: ['haiku', 'limerick', 'tanka', 'senryu'],
        tribulations: ['memorial', 'farewell', 'get-well-soon','apology','divorce','hard-times','missing-you','conflict','lost-pet']
    };

    // Define display names for poem types
    const displayNames = {
        'free verse': 'Free Verse',
        'love': 'Romantic/Love Poem',
        'funny': 'Funny/Humorous',
        'inspirational': 'Inspirational/Motivational',
        'angry': 'Angry/Intense',
        'extreme': 'Extreme/Bold',
        'holiday': 'Holiday',
        'birthday': 'Birthday',
        'anniversary': 'Anniversary',
        'nature': 'Nature',
        'friendship': 'Friendship',
        'religious-islam': 'Islamic/Muslim',
        'religious-christian': 'Christian',
        'religious-judaism': 'Jewish/Judaism',
        'religious-general': 'Spiritual/General',
        'twinkle': 'Twinkle Twinkle',
        'roses': 'Roses are Red',
        'knock-knock': 'Knock Knock',
        'hickory dickory dock': 'Hickory Dickory Dock',
        'nursery-rhymes': 'Nursery Rhymes',
        'william-shakespeare': 'William Shakespeare Style',
        'dante-alighieri': 'Dante Alighieri Style',
        'rumi': 'Rumi Style',
        'emily-dickinson': 'Emily Dickinson Style',
        'robert-frost': 'Robert Frost Style',
        'langston-hughes': 'Langston Hughes Style',
        'sylvia-plath': 'Sylvia Plath Style',
        'pablo-neruda': 'Pablo Neruda Style',
        'walt-whitman': 'Walt Whitman Style',
        'edgar-allan-poe': 'Edgar Allan Poe Style',
        'pick-up': 'Pick-Up Lines',
        'roast-you': 'Roast You',
        'first-date-feel': 'First Date Feel',
        'love-at-first-sight': 'Love at First Sight',
        'new-job': 'New Job',
        'graduation': 'Graduation',
        'wedding': 'Wedding',
        'engagement': 'Engagement',
        'new-baby': 'New Baby',
        'promotion': 'Promotion',
        'new-home': 'New Home',
        'new-car': 'New Car',
        'new-pet': 'New Pet',
        'first-day-of-school': 'First Day of School',
        'retirement': 'Retirement',
        'new-year': 'New Year',
        'valentines-day': 'Valentines Day',
        'ramadan': 'Ramadan',
        'easter': 'Easter',
        'mother-day': 'Mother Day',
        'father-day': 'Father Day',
        'independence-day': 'Independence Day',
        'halloween': 'Halloween',
        'thanksgiving': 'Thanksgiving',
        'christmas': 'Christmas',
        'hanukkah': 'Hanukkah',
        'diwali': 'Diwali',
        'new-year-eve': 'New Year Eve',
        'rap/hiphop': 'Rap/Hip-Hop',
        'country': 'Country',
        'rock': 'Rock',
        'pop': 'Pop',
        'jazz': 'Jazz',
        'eminem': 'Eminem',
        'taylor-swift': 'Taylor Swift',
        'drake': 'Drake',
        '50cent': '50 Cent',
        'lil-wayne': 'Lil Wayne',
        'doja-cat': 'Doja Cat',
        'nicki-minaj': 'Nicki Minaj',
        'kendrick-lamar': 'Kendrick Lamar',
        'j. cole': 'J. Cole',
        'elvis-presley': 'Elvis Presley',
        'tupac': 'Tupac Shakur',
        'biggie-smalls': 'Biggie Smalls',
        'buddy-holly': 'Buddy Holly',
        'luis-armstrong': 'Luis Armstrong',
        'haiku': 'Haiku',
        'limerick': 'Limerick ',
        'tanka': 'Tanka',
        'senryu': 'Senryu',
        'memorial': 'In Memory/RIP',
        'farewell': 'Farewell/Goodbye',
        'get-well-soon': 'Get Well Soon',
        'apology': 'Apology/Sorry',
        'divorce': 'Divorce/Breakup',
        'hard-times': 'Hard Times/Struggles',
        'missing-you': 'Missing You',
        'conflict': 'Conflict/Disagreement',
        'lost-pet': 'Lost Pet'
    };

    // Free types that are available to all users
    const freeTypes = ['free verse', 'love', 'funny', 'inspirational'];

    // Map of poem type to its appropriate group
    const groupMap = {};
    for (const [category, types] of Object.entries(poemCategories)) {
        types.forEach(type => groupMap[type] = category);
    }

    // Process each poem type and add to appropriate group
    Object.keys(displayNames).forEach(poemTypeId => {
        const option = document.createElement('option');
        option.value = poemTypeId;

        // Check access
        const isFree = freeTypes.includes(poemTypeId);
        const hasAccess = isFree || isPremium;

        if (!hasAccess) {
            option.textContent = `${displayNames[poemTypeId]} 🔒`;
            option.classList.add('premium-option');
            option.disabled = true;
        } else {
            option.textContent = displayNames[poemTypeId];
        }

        // Add to appropriate group
        const category = groupMap[poemTypeId];
        switch(category) {
            case 'standard': standardGroup.appendChild(option); break;
            case 'religious': religiousGroup.appendChild(option); break;
            case 'fun': funGroup.appendChild(option); break;
            case 'famousPoets': famousPoetsGroup.appendChild(option); break;
            case 'flirtyFun': flirtyFunGroup.appendChild(option); break;
            case 'congratulations': congratulationsGroup.appendChild(option); break;
            case 'music': musicGroup.appendChild(option); break;
            case 'artist': artistGroup.appendChild(option); break;
            case 'holidays': holidaysGroup.appendChild(option); break;
            case 'classic': classicGroup.appendChild(option); break;
            case 'tribulations': tribulationsGroup.appendChild(option); break;
            default: poemTypeSelect.appendChild(option);
        }

        // Update cache
        accessCache.poemTypes[poemTypeId] = hasAccess;
    });

    // Add groups to select
    poemTypeSelect.appendChild(standardGroup); 
    poemTypeSelect.appendChild(religiousGroup);
    poemTypeSelect.appendChild(funGroup);
    poemTypeSelect.appendChild(famousPoetsGroup);
    poemTypeSelect.appendChild(flirtyFunGroup);
    poemTypeSelect.appendChild(congratulationsGroup);
    poemTypeSelect.appendChild(musicGroup);
    poemTypeSelect.appendChild(artistGroup);
    poemTypeSelect.appendChild(holidaysGroup);
    poemTypeSelect.appendChild(classicGroup);
    poemTypeSelect.appendChild(tribulationsGroup);

    // Restore selection
    if (currentSelection && poemTypeSelect.querySelector(`option[value="${currentSelection}"]`)) {
        poemTypeSelect.value = currentSelection;
    } else {
        poemTypeSelect.value = 'free verse';
    }

    // Add premium indicator if needed
    if (!isPremium) {
        const legend = document.createElement('div');
        legend.className = 'small text-muted mt-2 premium-legend';
        legend.innerHTML = '🔒 Premium poem types. <a href="/upgrade" class="text-primary">Upgrade</a> to unlock all poem types.';
        poemTypeSelect.parentNode.appendChild(legend);
    }
}

/**
 * Update the frame options based on membership
 * @param {Array} frames - Array of frame options with availability flags
 */
function updateFrameOptions(frames) {
    const frameOptions = document.querySelectorAll('.frame-option');
    if (frameOptions.length === 0) return;
    
    // Store available frames
    frames.forEach(frame => {
        accessCache.frames[frame.id] = frame.free || isPremium;
    });
    
    // Update UI for each frame option
    frameOptions.forEach(frameOption => {
        const frameId = frameOption.getAttribute('data-frame-id');
        
        // Check if we have this frame in our available frames
        const frameData = frames.find(f => f.id === frameId);
        
        if (frameData && (!frameData.free && !isPremium)) {
            // Mark as premium but don't fully disable the option
            const frameImage = frameOption.querySelector('img');
            if (frameImage) {
                frameImage.classList.add('premium-overlay');
            }
            
            // Add lock icon badge
            const badge = document.createElement('span');
            badge.className = 'badge bg-secondary position-absolute top-0 end-0 m-2';
            badge.innerHTML = '🔒 Premium';
            frameOption.appendChild(badge);
            
            // Add lock overlay for visual indication
            const lockOverlay = document.createElement('div');
            lockOverlay.className = 'position-absolute top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center';
            lockOverlay.style.backgroundColor = 'rgba(0, 0, 0, 0.3)';
            lockOverlay.style.zIndex = '1';
            lockOverlay.style.borderRadius = 'inherit';
            
            // Add upgrade link
            const upgradeLink = document.createElement('a');
            upgradeLink.href = '/upgrade';
            upgradeLink.className = 'btn btn-sm btn-primary';
            upgradeLink.innerHTML = 'Upgrade to unlock';
            lockOverlay.appendChild(upgradeLink);
            
            frameOption.style.position = 'relative';
            frameOption.appendChild(lockOverlay);
            
            // Don't completely disable radio button so users can still interact with it
            // which will trigger our upgrade prompt
            const radioInput = frameOption.querySelector('input[type="radio"]');
            if (radioInput) {
                radioInput.dataset.premium = 'true';
            }
        }
    });
    
    // Add frame selection handler
    document.querySelectorAll('input[name="frameStyle"][data-premium="true"]').forEach(radio => {
        radio.addEventListener('click', function(e) {
            if (!isPremium) {
                // If premium and not a premium member, show upgrade prompt
                e.preventDefault();
                showUpgradePrompt('frame');
                
                // Reset to default frame
                document.querySelector('input[name="frameStyle"][value="classic"]').checked = true;
            }
        });
    });
}

/**
 * Check if a user has access to a specific feature
 * @param {string} featureType - The type of feature ('poem_type' or 'frame')
 * @param {string} featureId - The ID of the feature
 * @returns {Promise<boolean>} Promise resolving to access status
 */
function checkFeatureAccess(featureType, featureId) {
    // Check cache first
    if (featureType === 'poem_type' && accessCache.poemTypes.hasOwnProperty(featureId)) {
        return Promise.resolve(accessCache.poemTypes[featureId]);
    }
    
    if (featureType === 'frame' && accessCache.frames.hasOwnProperty(featureId)) {
        return Promise.resolve(accessCache.frames[featureId]);
    }
    
    // If not in cache, fetch from server
    return fetch('/api/check-access', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            type: featureType,
            id: featureId
        })
    })
    .then(response => response.json())
    .then(data => {
        // Update cache
        if (featureType === 'poem_type') {
            accessCache.poemTypes[featureId] = data.has_access;
        } else if (featureType === 'frame') {
            accessCache.frames[featureId] = data.has_access;
        }
        
        // Update premium status
        isPremium = data.is_premium;
        
        return data.has_access;
    })
    .catch(error => {
        console.error('Error checking feature access:', error);
        return false; // Default to no access on error
    });
}

/**
 * Show upgrade prompt when trying to access premium features
 * @param {string} featureType - The type of feature ('poem_type' or 'frame')
 */
function showUpgradePrompt(featureType) {
    let title, message;
    
    if (featureType === 'poem_type') {
        title = 'Premium Poem Type';
        message = 'This poem type is only available to Premium members. Upgrade to unlock all poem types!';
    } else if (featureType === 'frame') {
        title = 'Premium Frame Style';
        message = 'This frame design is only available to Premium members. Upgrade to unlock all frame designs!';
    } else {
        title = 'Premium Feature';
        message = 'This feature is only available to Premium members. Upgrade to unlock!';
    }
    
    // Create or update modal
    let modal = document.getElementById('upgradePromptModal');
    
    if (!modal) {
        // Create modal if it doesn't exist
        const modalHtml = `
            <div class="modal fade" id="upgradePromptModal" tabindex="-1" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header bg-primary text-white">
                            <h5 class="modal-title"><i class="fas fa-star me-2"></i><span id="upgradePromptTitle"></span></h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <p id="upgradePromptMessage"></p>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Not Now</button>
                            <a href="/upgrade" class="btn btn-primary">
                                <i class="fas fa-arrow-up me-1"></i> Upgrade to Premium
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Add to document
        const modalContainer = document.createElement('div');
        modalContainer.innerHTML = modalHtml;
        document.body.appendChild(modalContainer.firstChild);
        
        modal = document.getElementById('upgradePromptModal');
    }
    
    // Update modal content
    document.getElementById('upgradePromptTitle').textContent = title;
    document.getElementById('upgradePromptMessage').textContent = message;
    
    // Show the modal
    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
}

/**
 * Setup upgrade prompts throughout the UI
 */
function setupUpgradePrompts() {
    // For poem types
    document.addEventListener('change', function(e) {
        if (e.target.id === 'poemTypeSelect') {
            const selectedType = e.target.value;
            
            checkFeatureAccess('poem_type', selectedType).then(hasAccess => {
                if (!hasAccess) {
                    // Reset selection to default
                    e.target.value = 'free verse';
                    
                    // Show upgrade prompt
                    showUpgradePrompt('poem_type');
                }
            });
        }
    });
    
    // For frame styles
    document.addEventListener('change', function(e) {
        if (e.target.name === 'frameStyle') {
            const selectedFrame = e.target.value;
            
            checkFeatureAccess('frame', selectedFrame).then(hasAccess => {
                if (!hasAccess) {
                    // Reset selection to default
                    document.querySelector('input[name="frameStyle"][value="classic"]').checked = true;
                    
                    // Show upgrade prompt
                    showUpgradePrompt('frame');
                }
            });
        }
    });
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', initMembership);