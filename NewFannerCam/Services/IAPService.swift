//
//  IAPService.swift
//  NewFannerCam
//
//  Created by Jin on 2/19/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void
public typealias ReceiptRefreshCompletionHandler = (_ success: Bool, _ productIds: [String]?) -> Void

extension Notification.Name {
    static let IAPServicePurchaseNotification = Notification.Name("IAPServicePurchaseNotification")
}

open class IAPService: NSObject  {
  
    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    private var receiptRequest: SKReceiptRefreshRequest?
    private var receiptRefreshCompletionHandler: ReceiptRefreshCompletionHandler?
    
    public init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
        for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
    
}

// MARK: - StoreKit API

extension IAPService {
  
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return UserDefaults.standard.bool(forKey: productIdentifier)
        //return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases(_ completionHandler: @escaping ReceiptRefreshCompletionHandler) {
       // for purchasedID in purchasedProductIdentifiers {
            //UserDefaults.standard.removeObject(forKey: purchasedID)
       // }
        receiptRefreshCompletionHandler = completionHandler
        purchasedProductIdentifiers.removeAll()
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public func refreshReceipt(_ completionHandler: @escaping ReceiptRefreshCompletionHandler){
        receiptRequest?.cancel()
        receiptRefreshCompletionHandler = completionHandler
        
        receiptRequest = SKReceiptRefreshRequest(receiptProperties: nil)
        receiptRequest!.delegate = self
        receiptRequest!.start()
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPService: SKProductsRequestDelegate {

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.count > 0 {
           // NotificationCenter.default.post(name: .IAPServiceRestoreNotification, object: queue)
            checkIAPPurchaseStatus { (success, error, productIds) in
                   self.receiptRefreshCompletionHandler?(true, productIds)
                   self.clearRequestAndHandler(isProductReq: false)
            }
            for transaction in queue.transactions{
                if transaction.transactionState == .restored{
                    SKPaymentQueue.default().finishTransaction(transaction)
                }
            }
        }else{
            Utiles.setHUD(false)
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        Utiles.setHUD(false)
    }

    public func requestDidFinish(_ request: SKRequest) {
        if request is SKReceiptRefreshRequest{
            checkIAPPurchaseStatus { (success, error, productIds) in
                if(self.receiptRefreshCompletionHandler != nil){
                    self.receiptRefreshCompletionHandler?(true, productIds)
                    self.clearRequestAndHandler(isProductReq: false)
                }else{
                    Utiles.setHUD(false)
                }
            }
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        MessageBarService.shared.error("Failed to load list of products. The reason: " + error.localizedDescription)
        productsRequestCompletionHandler?(false, nil)
        receiptRefreshCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler(isProductReq : Bool = true) {
        if isProductReq{
            productsRequest = nil
            productsRequestCompletionHandler = nil
        }else{
            receiptRequest = nil
            receiptRefreshCompletionHandler = nil
        }
    }
    
    private func refreshBuyProducts(productIdentifier:String){
        if(UserDefaults.standard.bool(forKey: productIdentifier)){
            purchasedProductIdentifiers.insert(productIdentifier)
        }
    }
    
    private func loadReceipt() -> (Data?, URL?) {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return (nil, nil)
        }
        
        do {
            let data = try Data(contentsOf: url)
            return (data, url)
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return (nil, nil)
        }
    }
    
    public func checkIAPPurchaseStatus(_ completion: @escaping (Bool, String?, [String]?) -> Void) {
        if let receipt = loadReceipt().0, let receiptUrl = loadReceipt().1 {
            let sandbox = receiptUrl.lastPathComponent == "sandboxReceipt"
            // Create the JSON object that describes the request
            let requestContent = [
                "receipt-data": receipt.base64EncodedString(options: .init(rawValue: 0)),
                "password": "d79b553472a94386bec40e86e690bbd4",
                "exclude-old-transactions": true
            ] as [String: Any]
            // Create a POST request with the receipt data.
            if let requestData = try? JSONSerialization.data(withJSONObject: requestContent, options: .init(rawValue: 0)) {
                var urlString = sandbox ? "https://sandbox." : "https://buy."
                urlString += "itunes.apple.com/verifyReceipt"
                
                var storeRequest = URLRequest(url: URL(string: urlString)!)
                storeRequest.httpMethod = "POST"
                storeRequest.httpBody = requestData
                let session = URLSession(configuration: URLSessionConfiguration.default)
                let task = session.dataTask(with: storeRequest, completionHandler: { [weak self] (data, response, error) in
                    do {
                        if(data != nil){
                            let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                           // print("=======>",jsonResponse)
                            let productIds = self?.getProductExpirationFromResponse(jsonResponse: jsonResponse as! NSDictionary)
                           // let productIds = self?.checkProductExpiration(jsonResponse: jsonResponse as! NSDictionary)
                            completion(true, nil, productIds!)
                        }else{
                            completion(true, nil, nil)
                        }
                    } catch let parseError {
                        print(parseError)
                        completion(true, (parseError as! String), [String]())
                    }
                })
                task.resume()
            }
        }else{
            completion(true, nil, [String]())
        }
    }
    
    private func getProductExpirationFromResponse(jsonResponse: NSDictionary) -> [String]?{
        
        if let receipt : NSDictionary = jsonResponse["receipt"] as? NSDictionary {
            var productInfoData : [String:NSDictionary] = [String:NSDictionary]()
            if let receiptInfo: NSArray = receipt["in_app"] as? NSArray {
                receiptInfo.forEach { (productInfo) in
                    let productInf : NSDictionary = productInfo as! NSDictionary
                    productInfoData.updateValue(productInf, forKey: productInf["product_id"] as! String)
                }
            }
            productInfoData.forEach { (productData) in
                let (_, value) = productData
                _ = setProductData(lastReceipt: value)
            }
            DataManager.shared.setProductGroupData(productGroup: productInfoData)
            return [String](productInfoData.keys)
        }
        return nil
    }
    
    private func checkProductExpiration(jsonResponse: NSDictionary) ->  [String]? {
        if let receiptInfo: NSArray = jsonResponse["latest_receipt_info"] as? NSArray {
            var productInfoData : [String:NSDictionary] = [String:NSDictionary]()
            receiptInfo.forEach { (productInfo) in
                let lastReceipt = productInfo as! NSDictionary
                let productId = setProductData(lastReceipt: lastReceipt)
                productInfoData.updateValue(lastReceipt, forKey: productId)
            }
            DataManager.shared.setProductGroupData(productGroup: productInfoData)
            return [String](productInfoData.keys)
        }
        return nil
    }
    
    private func setProductData(lastReceipt: NSDictionary) -> String{
        
        var expireDateProduct : Date = Date()
        if let expiresDate = lastReceipt["expires_date_ms"] as? String {
            expireDateProduct = Date(timeIntervalSince1970: TimeInterval(expiresDate)!/1000)
        }
        let productId = lastReceipt["product_id"] as! String
        let isPurchase = expireDateProduct > Date()
        storeProductExpiration(productId: productId, isPurchased: isPurchase)
        print("ProductId: \(productId) \n Current Date: \(Date()) \n expireDateProduct: \(expireDateProduct) \n isPurchased: \(isPurchase)")
        return productId
    }
    
    private func storeProductExpiration(productId: String, isPurchased: Bool){
       purchasedProductIdentifiers.insert(productId)
       UserDefaults.standard.set(isPurchased, forKey: productId)
       UserDefaults.standard.synchronize()
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPService: SKPaymentTransactionObserver {

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                print(transaction, "Diferred")
                break
            case .purchasing:
                print(transaction, "Purchasing")
                break
            @unknown default:
                break
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        SKPaymentQueue.default().finishTransaction(transaction)
        let productId = transaction.payment.productIdentifier.components(separatedBy: ".").last
        if productId!.lowercased().contains("matches"){
            deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier, isPurchased: true)
        }else{
            self.restorePurchases { (success, productIds) in
                guard productIds == nil else{
                    for productId in productIds!{
                        NotificationCenter.default.post(name: .IAPServicePurchaseNotification, object: productId)
                    }
                    return
                }
            }
        }
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        print("restore... \(productIdentifier)")
       // deliverPurchaseNotificationFor(identifier: productIdentifier)
        refreshBuyProducts(productIdentifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        if let transactionError = transaction.error as NSError?, let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue
        {
            MessageBarService.shared.error("Transaction Error: " + localizedDescription)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        Utiles.setHUD(false)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?, isPurchased: Bool) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(isPurchased, forKey: identifier)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: .IAPServicePurchaseNotification, object: identifier)
    }
    
}
