# Currency Converter

## What It Does
Convert EUR to several currencies with live rates.

## Key Files
```
Models/
├── Currency.swift           # Currency data model
├── CurrencyRate.swift       # Realm cache model
└── Error.swift              # API error handling

Services/
├── CurrencyServiceAPI.swift # Fixer.io API integration
└── CurrencyConversionManager.swift # Conversion logic

UI/
├── ViewController.swift     # Main controller
├── CurrencyUIManager.swift  # UI updates
├── CurrencyInputHandler.swift # Input formatting
└── CurrencyBottomSheetVC.swift # Currency picker
```

## Core Flow
1. User selects target currency → `CurrencyBottomSheetViewController`
2. User enters amount → `CurrencyInputHandler` formats input
3. Tap Convert → `CurrencyAPIService` fetches rate (with caching)
4. Real-time conversion → `CurrencyConversionManager` calculates

## API Details
- **Endpoint**: `https://data.fixer.io/api/latest`
- **Method**: EUR base, cross-rate calculation
- **Cache**: 1-hour Realm storage

## Testing

### Unit Tests (`Cowrywise_TaskTests.swift`)
**What's Tested:**
- ✅ Currency model initialization
- ✅ API error handling (HTTP codes 400, 401, 403, 404, 429)
- ✅ API response error codes (104, 105, 601, 602, 606)
- ✅ Currency rate caching (save, retrieve, expiry)
- ✅ Real-time conversion logic (valid/invalid inputs)
- ✅ Text input formatting (commas, decimals)
- ✅ Currency formatting performance


### UI Tests (`Cowrywise_TaskUITests.swift`)
**Complete User Journey:**
- ✅ App launches with EUR as base currency
- ✅ Currency selection via bottom sheet
- ✅ Search functionality in currency picker
- ✅ Exchange rate fetching and display
- ✅ Real-time conversion as user types
- ✅ Amount formatting with commas (10,000+)
- ✅ Convert button state management

**Test Flow:**
```
testCompleteUserJourneyEndToEnd()
├── verifyInitialAppState()       # EUR shown, buttons exist
├── selectCurrency("USD")         # Bottom sheet, search, selection
├── performInitialConversion()    # Exchange rate established
└── enterAmountAndVerifyConversion() # Real-time formatting/conversion
```

## Quick Setup
1. Install: RealmSwift, PromiseKit, Alamofire, SwiftyJSON
2. Add Fixer.io API key to CurrencyAPIService
3. Run tests to verify


## Architecture Pattern
**Protocol-Delegate** based with clear separation:
- Models handle data
- Services handle API/business logic  
- UI components handle presentation
- Managers coordinate between layers
