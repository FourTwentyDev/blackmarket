let config = null;
let currentItems = [];
let currentListings = [];

// Initialize UI
document.addEventListener('DOMContentLoaded', () => {
    let currentForm = null;

    // Tab switching with proper cleanup
    document.querySelectorAll('.tab-btn').forEach(button => {
        button.addEventListener('click', () => {
            // Remove active classes
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(content => {
                content.classList.remove('active');
                // Remove any ongoing animations
                content.style.animation = 'none';
                content.offsetHeight; // Trigger reflow
                content.style.animation = null;
            });

            // Cleanup old form if exists
            if (currentForm) {
                currentForm.removeEventListener('submit', handleCreateListing);
                currentForm = null;
            }

            // Activate new tab
            button.classList.add('active');
            const newContent = document.getElementById(`${button.dataset.tab}-tab`);
            newContent.classList.add('active');

            // Setup new form if switching to create tab
            if (button.dataset.tab === 'create') {
                setupCreateForm();
            }
        });
    });

    // Initial form setup if starting on create tab
    if (document.querySelector('.tab-btn[data-tab="create"]').classList.contains('active')) {
        setupCreateForm();
    }

    // Close button with animation cleanup
    const closeUI = () => {
        // Cleanup any ongoing animations
        document.querySelectorAll('.tab-content').forEach(content => {
            content.style.animation = 'none';
            content.offsetHeight; // Trigger reflow
            content.style.animation = null;
        });

        // Cleanup form
        if (currentForm) {
            currentForm.removeEventListener('submit', handleCreateListing);
            currentForm = null;
        }

        document.getElementById('blackmarket').classList.add('hidden');
        fetch(`https://fourtwenty_blackmarket/closeUI`, {
            method: 'POST',
            body: JSON.stringify({})
        });

        if (window.timeUpdateInterval) {
            clearInterval(window.timeUpdateInterval);
            window.timeUpdateInterval = null;
        }
    };

    document.getElementById('close-btn').addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        closeUI();
    });

    // Add listener for 'Esc' key to close UI
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeUI();
        }
    });

    // Listing type change handler
    document.getElementById('listing-type').addEventListener('change', (e) => {
        const durationGroup = document.querySelector('.duration-group');
        durationGroup.classList.toggle('hidden', e.target.value !== 'auction');
    });
});

// Setup create form function
function setupCreateForm() {
    const form = document.getElementById('create-listing-form');
    if (form) {
        form.reset(); // Reset form state
        currentForm = form;
        form.addEventListener('submit', handleCreateListing);
    }
}

// Create listing handler
async function handleCreateListing(e) {
    e.preventDefault();
    e.stopPropagation();

    const container = document.querySelector('.item-select-container');
    const selectedIndex = container.dataset.selectedIndex;
    
    if (selectedIndex === '' || !currentItems[selectedIndex]) {
        console.error('No item selected');
        return;
    }

    const selectedItem = currentItems[selectedIndex];
    const amount = parseInt(document.getElementById('amount-input').value);
    const price = parseInt(document.getElementById('price-input').value);
    const isAuction = document.getElementById('listing-type').value === 'auction';
    const duration = parseInt(document.getElementById('duration-input').value);

    if (!amount || !price || amount < 1 || price < (config?.MinimumPrice || 0)) {
        console.error('Invalid amount or price');
        return;
    }

    try {
        await fetch(`https://fourtwenty_blackmarket/createListing`, {
            method: 'POST',
            body: JSON.stringify({
                itemName: selectedItem.name,
                amount: Math.min(amount, selectedItem.count),
                price,
                isAuction,
                duration: isAuction ? Math.min(duration, config?.MaxAuctionTime || 72) : 0
            })
        });

        // Reset form and UI after successful creation
        const form = document.getElementById('create-listing-form');
        form.reset();
        
        // Reset item select
        container.dataset.selectedIndex = '';
        const details = container.querySelector('.item-details');
        if (details) {
            details.innerHTML = `
                <div class="item-name">${config.translations.choose_item || 'Choose an item'}</div>
                <div class="item-count">
                    <i class="fas fa-cube"></i>
                    <span>0 ${config.translations.items_available || 'available'}</span>
                </div>
            `;
        }
        const previewImg = container.querySelector('.item-image-preview img');
        if (previewImg) {
            previewImg.style.display = 'none';
            previewImg.src = '';
        }
        
        document.querySelector('.duration-group').classList.add('hidden');
        
        // Request updated listings
        fetch(`https://fourtwenty_blackmarket/getListings`, {
            method: 'POST',
            body: JSON.stringify({})
        });
        
        // Switch to browse tab
        document.querySelector('.tab-btn[data-tab="browse"]').click();
    } catch (error) {
        console.error('Error creating listing:', error);
    }
}

// Remove listing function
async function removeListing(listingId) {
    if (!listingId) return;
    
    await fetch(`https://fourtwenty_blackmarket/removeListing`, {
        method: 'POST',
        body: JSON.stringify({ listingId })
    });
}

function getCurrentPlayerIdentifier() {
    return fetch(`https://fourtwenty_blackmarket/getCurrentPlayer`, {
        method: 'POST',
        body: JSON.stringify({})
    })
    .then(response => response.json());
}

// Listen for messages from FiveM client
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (!data.type) return;

    switch (data.type) {
        case 'openUI':
            updateUITranslations();
            document.getElementById('blackmarket').classList.remove('hidden');
            document.getElementById('market-name').textContent = data.market || 'Black Market';
            config = data.config || {};
            
            if (data.listings) {
                updateListings(data.listings);
            }
            
            fetchPlayerItems();
            break;
            
        case 'updateListings':
            if (data.listings) {
                updateListings(data.listings);
            }
            break;
            
        case 'refreshListings':
            fetch(`https://fourtwenty_blackmarket/getListings`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            break;
    }
});

// Fetch player items
async function fetchPlayerItems() {
    try {
        const response = await fetch(`https://fourtwenty_blackmarket/getPlayerItems`, {
            method: 'POST',
            body: JSON.stringify({})
        });
        const items = await response.json();
        if (Array.isArray(items)) {
            currentItems = items;
            updateItemSelect(items);
        }
    } catch (error) {
        console.error('Error fetching items:', error);
    }
}

// Update listings display
function formatTimeRemaining(endTimeStr) {
    const endTime = new Date(endTimeStr);
    const now = new Date();
    
    if (isNaN(endTime.getTime())) {
        return 'N/A';
    }
    
    const diff = endTime - now;
    if (diff <= 0) {
        return 'Ended';
    }
    
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    if (hours > 24) {
        const days = Math.floor(hours / 24);
        const remainingHours = hours % 24;
        return `${days}d ${remainingHours}h ${minutes}m`;
    }
    
    return `${hours}h ${minutes}m`;
}

async function updateListings(listings) {
    const container = document.getElementById('listings-container');
    
    if (!Array.isArray(listings) || listings.length === 0) {
        container.innerHTML = `<div class="no-listings">
            <i class="fas fa-box-open"></i>
            ${config.translations.no_listings || 'No listings available'}
        </div>`;
        return;
    }

    // Get current player identifier
    let currentPlayer = await getCurrentPlayerIdentifier();
    currentListings = listings;
    
    container.innerHTML = listings.map(listing => {
        const isAuction = listing.is_auction === true || listing.is_auction === 1;
        const currentPrice = isAuction ? (listing.highest_bid || listing.price) : listing.price;
        const isHighestBidder = listing.highest_bidder === currentPlayer;
        const isOwner = listing.seller === currentPlayer;
        
        let endTimeDisplay = 'N/A';
        let timeRemaining = '';
        if (isAuction && listing.end_time) {
            const endTime = new Date(listing.end_time);
            if (!isNaN(endTime.getTime())) {
                endTimeDisplay = endTime.toLocaleString();
                timeRemaining = formatTimeRemaining(listing.end_time);
            }
        }
        
        return `
            <div class="listing" data-id="${listing.id}">
                ${isAuction && isHighestBidder ? `
                    <div class="highest-bid-marker" title="${config.translations.your_bid || 'Your Highest Bid'}">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M12 2L14.4 9.2H22L16 13.8L18.4 21L12 16.4L5.6 21L8 13.8L2 9.2H9.6L12 2Z" fill="currentColor"/>
                        </svg>
                    </div>
                ` : ''}
                <div class="listing-info">
                    <div class="item-header">
                        <div class="item-image">
                            <img src="${config.ItemImagePath}${listing.item_name}.png" alt="${listing.item_label}" onerror="this.src='img/default.png'">
                        </div>
                        <h3>${listing.item_label}</h3>
                    </div>
                    <div class="listing-details">
                        <p><i class="fas fa-cube"></i> ${config.translations.amount || 'Amount'}: ${listing.amount}</p>
                        <p class="seller"><i class="fas fa-user"></i> ${config.translations.seller || 'Seller'}: ${listing.seller_name}</p>
                        ${isAuction ? `
                            <p><i class="fas fa-gavel"></i> ${config.translations.current_bid || 'Current Bid'}: ${config.translations.currency_symbol || '$'}${currentPrice.toLocaleString()}</p>
                            <p><i class="fas fa-clock"></i> ${config.translations.ends_at || 'Ends at'}: ${endTimeDisplay}</p>
                            <p class="time-remaining"><i class="fas fa-hourglass-half"></i> ${config.translations.time_remaining || 'Time Remaining'} ${timeRemaining}</p>
                        ` : `
                            <p><i class="fas fa-tag"></i> ${config.translations.price || 'Price'}: ${config.translations.currency_symbol || '$'}${currentPrice.toLocaleString()}</p>
                        `}
                    </div>
                </div>
                <div class="listing-actions">
                ${isOwner ? `
                    <button class="remove-btn" onclick="removeListing(${listing.id})">
                        <i class="fas fa-trash"></i>
                        ${config.translations.remove_listing || 'Remove Listing'}
                    </button>
                ` : isAuction ? `
                    <div class="bid-container">
                        <div class="bid-input-wrapper">
                            <input type="number" 
                                   class="bid-input" 
                                   placeholder="${config.translations.enter_bid || 'Enter bid'}" 
                                   min="${currentPrice + 1}"
                                   ${isHighestBidder ? 'title="' + (config.translations.already_highest || 'You are already the highest bidder') + '"' : ''}>
                        </div>
                        <button class="bid-btn" onclick="placeBid(${listing.id}, this)">
                            <i class="fas fa-gavel"></i>
                            ${config.translations.place_bid || 'Place Bid'}
                        </button>
                    </div>
                ` : `
                    <button class="buy-btn" onclick="purchaseItem(${listing.id})">
                        <i class="fas fa-shopping-cart"></i> 
                        ${config.translations.buy_now || 'Buy Now'}
                    </button>
                `}
                </div>
            </div>
        `;
    }).join('');

    // Optional: Update times every minute
    if (!window.timeUpdateInterval) {
        window.timeUpdateInterval = setInterval(() => {
            document.querySelectorAll('.time-remaining').forEach(element => {
                const listingId = element.closest('.listing').dataset.id;
                const listing = currentListings.find(l => l.id == listingId);
                if (listing && listing.end_time) {
                    element.innerHTML = `<i class="fas fa-hourglass-half"></i> ${config.translations.time_remaining || 'Time Remaining'}: ${formatTimeRemaining(listing.end_time)}`;
                }
            });
        }, 60000); // Update every minute
    }
}

// Purchase item function
async function purchaseItem(listingId) {
    if (!listingId) return;
    
    await fetch(`https://fourtwenty_blackmarket/purchaseItem`, {
        method: 'POST',
        body: JSON.stringify({ listingId })
    });
}

// Place bid function
async function placeBid(listingId, buttonElement) {
    if (!listingId) return;

    const bidInput = buttonElement.parentElement.querySelector('.bid-input');
    const bidAmount = parseInt(bidInput.value);
    
    if (!bidAmount) return;

    await fetch(`https://fourtwenty_blackmarket/placeBid`, {
        method: 'POST',
        body: JSON.stringify({ 
            listingId, 
            bidAmount 
        })
    });

    bidInput.value = '';
}

// Update UI translations
function updateUITranslations() {
    if (!config || !config.translations) return;
    
    document.querySelectorAll('[data-translation-key]').forEach(element => {
        const key = element.getAttribute('data-translation-key');
        if (config.translations[key]) {
            if (element.tagName === 'INPUT' && element.getAttribute('type') === 'placeholder') {
                element.placeholder = config.translations[key];
            } else {
                element.textContent = config.translations[key];
            }
        }
    });
}

// Update item select function
function updateItemSelect(items) {
    const select = document.getElementById('item-select');
    const container = select.parentElement;
    
    // Add a data attribute to track selected index
    container.dataset.selectedIndex = '';
    
    // Cleanup existing elements first
    const existingWrapper = container.querySelector('.item-select-wrapper');
    const existingDropdown = container.querySelector('.item-dropdown');
    if (existingWrapper) existingWrapper.remove();
    if (existingDropdown) existingDropdown.remove();
    
    // Create custom select wrapper
    const wrapper = document.createElement('div');
    wrapper.className = 'item-select-wrapper';
    
    // Create preview area
    const preview = document.createElement('div');
    preview.className = 'item-image-preview';
    preview.innerHTML = '<img src="" alt="" style="display: none;">';
    
    // Create details area
    const details = document.createElement('div');
    details.className = 'item-details';
    details.innerHTML = `
        <div class="item-name">${config.translations.choose_item || 'Choose an item'}</div>
        <div class="item-count">
            <i class="fas fa-cube"></i>
            <span>0 ${config.translations.items_available || 'available'}</span>
        </div>
    `;
    
    // Add dropdown arrow
    const arrow = document.createElement('i');
    arrow.className = 'fas fa-chevron-down dropdown-arrow';
    
    // Create dropdown list
    const dropdown = document.createElement('div');
    dropdown.className = 'item-dropdown';
    
    // Populate dropdown with items
    items.forEach((item, index) => {
        if (item && item.count > 0) {
            const dropdownItem = document.createElement('div');
            dropdownItem.className = 'dropdown-item';
            dropdownItem.innerHTML = `
                <img src="${config.ItemImagePath}${item.name}.png" alt="${item.name}">
                <div class="dropdown-item-details">
                    <div class="dropdown-item-name">${item.label}</div>
                    <div class="dropdown-item-count">x${item.count} ${config.translations.items_available || 'available'}</div>
                </div>
            `;
            
            dropdownItem.addEventListener('click', (e) => {
                e.stopPropagation();
                
                // Store the selected index
                container.dataset.selectedIndex = index.toString();
                select.value = index;
                
                const previewImg = preview.querySelector('img');
                previewImg.src = `${config.ItemImagePath}${item.name}.png`;
                previewImg.alt = item.name;
                previewImg.style.display = 'block';
                
                details.innerHTML = `
                    <div class="item-name">${item.label}</div>
                    <div class="item-count">
                        <i class="fas fa-cube"></i>
                        <span>x${item.count} ${config.translations.items_available || 'available'}</span>
                    </div>
                `;
                
                dropdown.classList.remove('active');
                arrow.style.transform = 'translateY(-50%)';
                
                const event = new Event('change');
                select.dispatchEvent(event);
            });
            
            dropdown.appendChild(dropdownItem);
        }
    });
    
    // Click handler for wrapper
    wrapper.addEventListener('click', (e) => {
        e.stopPropagation();
        if (!dropdown.contains(e.target)) {
            const wasActive = dropdown.classList.contains('active');
            document.querySelectorAll('.item-dropdown').forEach(d => {
                d.classList.remove('active');
            });
            dropdown.classList.toggle('active', !wasActive);
            arrow.style.transform = !wasActive 
                ? 'translateY(-50%) rotate(180deg)' 
                : 'translateY(-50%)';
        }
    });
    
    // Document click handler
    const documentClickHandler = (e) => {
        if (!container.contains(e.target)) {
            dropdown.classList.remove('active');
            arrow.style.transform = 'translateY(-50%)';
        }
    };
    
    // Remove existing click handler if any
    document.removeEventListener('click', documentClickHandler);
    // Add new click handler
    document.addEventListener('click', documentClickHandler);
    
    // Assemble the custom select
    wrapper.appendChild(preview);
    wrapper.appendChild(details);
    wrapper.appendChild(arrow);
    container.appendChild(wrapper);
    container.appendChild(dropdown);
    
    // Make sure the dropdown starts closed
    dropdown.classList.remove('active');
    arrow.style.transform = 'translateY(-50%)';
}
