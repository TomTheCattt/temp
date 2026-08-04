//
//  APIEndPoint.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Alamofire

// MARK: - HTTP Method

typealias HTTPMethod = Alamofire.HTTPMethod

// MARK: - APIEndpoint Protocol

protocol APIEndpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
    func asURLRequest() throws -> URLRequest
}

extension APIEndpoint {
    // P1 FIX: Replace force unwrap with fatalError + descriptive message
    var baseURL: URL {
        guard let url = URL(string: AppConfig.shared.baseURL) else {
            fatalError("[APIEndpoint] Invalid baseURL: '\(AppConfig.shared.baseURL)'. Check xcconfig / build settings.")
        }
        return url
    }
    var headers: HTTPHeaders? { nil }
    var parameters: Parameters? { nil }
    var encoding: ParameterEncoding {
        method == .get ? URLEncoding.default : JSONEncoding.default
    }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.timeoutInterval = AppConfig.shared.timeoutInterval

        if let headers = headers {
            headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.name) }
        }

        if let parameters = parameters {
            return try encoding.encode(request, with: parameters)
        }
        return request
    }
}

// MARK: - APIEnvelope (Server response wrapper)

nonisolated struct APIEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    let success: Bool?
    let data: T?
    let error: String?
    let message: String?
}

// MARK: - Example Endpoints

enum AuthEndpoint: APIEndpoint {
    case login(idToken: String)
    case register(idToken: String, name: String, phone: String?)
    case refreshToken(token: String)
    case logout
    case forgotPassword(phoneNumber: String)
    case resetPassword(token: String, password: String)
    case verifyEmail(token: String)
    case resendVerification(email: String)
    case changePassword(currentPassword: String, newPassword: String)

    var path: String {
        switch self {
        case .register:     return "/v1/auth/register"
        case .login:        return "/v1/auth/login"
        case .refreshToken: return "/v1/auth/refresh"
        case .logout:       return "/v1/auth/logout-all-devices"
        case .forgotPassword:      return "/v1/auth/forgot-password/phone"
        case .resetPassword:       return "/v1/auth/reset-password"
        case .verifyEmail:         return "/v1/auth/verify-email"
        case .resendVerification:  return "/v1/auth/resend-verification"
        case .changePassword:      return "/v1/auth/change-password"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register,
             .login,
             .refreshToken,
             .logout,
             .forgotPassword,
             .resetPassword,
             .verifyEmail,
             .resendVerification,
             .changePassword:
            return .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .login(let idToken):
            return ["idToken": idToken]
        case .register(let idToken, let name, let phone):
            var params: Parameters = ["idToken": idToken, "name": name]
            if let phone { params["phone"] = phone }
            return params
        case .refreshToken(let token):
            return ["refreshToken": token]
        case .logout:
            return nil
        case .forgotPassword(let phoneNumber):
            return ["phone_number": phoneNumber]
        case .resetPassword(let token, let password):
            return ["token": token, "password": password]
        case .verifyEmail(let token):
            return ["token": token]
        case .resendVerification(let email):
            return ["email": email]
        case .changePassword(let currentPassword, let newPassword):
            return ["current_password": currentPassword, "new_password": newPassword]
        }
    }
}

enum UserEndpoint: APIEndpoint {
    case profile
    case updateProfile(name: String)
    case settings
    case updateSettings(language: String?, biometricEnabled: Bool?, pushEnabled: Bool?, darkMode: Bool?)

    var path: String {
        switch self {
        case .profile, .updateProfile:
            return "/v1/user/profile"
        case .settings, .updateSettings:
            return "/v1/user/settings"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .profile, .settings:
            return .get
        case .updateProfile, .updateSettings:
            return .put
        }
    }

    var parameters: Parameters? {
        switch self {
        case .profile, .settings:
            return nil
        case .updateProfile(let name):
            return ["name": name]
        case .updateSettings(let language, let biometricEnabled, let pushEnabled, let darkMode):
            var params: Parameters = [:]
            if let language { params["language"] = language }
            if let biometricEnabled { params["biometric_enabled"] = biometricEnabled }
            if let pushEnabled { params["push_enabled"] = pushEnabled }
            if let darkMode { params["dark_mode"] = darkMode }
            return params
        }
    }
}

enum HomeEndpoint: APIEndpoint {
    case summary

    var path: String { "/v1/home/summary" }
    var method: HTTPMethod { .get }
}

enum AccountsEndpoint: APIEndpoint {
    case list
    case detail(id: String)
    case transactions(accountId: String, page: Int, perPage: Int)

    var path: String {
        switch self {
        case .list:
            return "/v1/accounts"
        case .detail(let id):
            return "/v1/accounts/\(id)"
        case .transactions(let accountId, _, _):
            return "/v1/accounts/\(accountId)/transactions"
        }
    }

    var method: HTTPMethod { .get }

    var parameters: Parameters? {
        switch self {
        case .transactions(_, let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .list, .detail:
            return nil
        }
    }
}

enum CardsEndpoint: APIEndpoint {
    case list
    case detail(id: String)

    var path: String {
        switch self {
        case .list:
            return "/v1/cards"
        case .detail(let id):
            return "/v1/cards/\(id)"
        }
    }

    var method: HTTPMethod { .get }
}

enum TransfersEndpoint: APIEndpoint {
    case validate(fromAccountId: String, toAccountNo: String, beneficiaryName: String, amountMinor: Int, toBankCode: String?)
    case confirm(
        fromAccountId: String,
        toAccountNo: String,
        beneficiaryName: String,
        amountMinor: Int,
        toBankCode: String?,
        description: String?,
        idempotencyKey: String
    )
    case detail(id: String)

    var path: String {
        switch self {
        case .validate:
            return "/v1/transfers/validate"
        case .confirm:
            return "/v1/transfers/confirm"
        case .detail(let id):
            return "/v1/transfers/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .detail:
            return .get
        case .validate, .confirm:
            return .post
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .confirm(_, _, _, _, _, _, let idempotencyKey):
            return ["Idempotency-Key": idempotencyKey]
        default:
            return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .validate(let fromAccountId, let toAccountNo, let beneficiaryName, let amountMinor, let toBankCode):
            var params: Parameters = [
                "from_account_id": fromAccountId,
                "to_account_no": toAccountNo,
                "beneficiary_name": beneficiaryName,
                "amount_minor": amountMinor
            ]
            if let toBankCode { params["to_bank_code"] = toBankCode }
            return params
        case .confirm(let fromAccountId, let toAccountNo, let beneficiaryName, let amountMinor, let toBankCode, let description, _):
            var params: Parameters = [
                "from_account_id": fromAccountId,
                "to_account_no": toAccountNo,
                "beneficiary_name": beneficiaryName,
                "amount_minor": amountMinor
            ]
            if let toBankCode { params["to_bank_code"] = toBankCode }
            if let description { params["description"] = description }
            return params
        case .detail:
            return nil
        }
    }
}

enum WithdrawalsEndpoint: APIEndpoint {
    case validate(accountId: String, amountMinor: Int, methodValue: String)
    case confirm(accountId: String, amountMinor: Int, methodValue: String, idempotencyKey: String)
    case detail(id: String)

    var path: String {
        switch self {
        case .validate:
            return "/v1/withdrawals/validate"
        case .confirm:
            return "/v1/withdrawals/confirm"
        case .detail(let id):
            return "/v1/withdrawals/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .detail:
            return .get
        case .validate, .confirm:
            return .post
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .confirm(_, _, _, let idempotencyKey):
            return ["Idempotency-Key": idempotencyKey]
        default:
            return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .validate(let accountId, let amountMinor, let methodValue),
             .confirm(let accountId, let amountMinor, let methodValue, _):
            return [
                "account_id": accountId,
                "amount_minor": amountMinor,
                "method": methodValue
            ]
        case .detail:
            return nil
        }
    }
}

enum BillsEndpoint: APIEndpoint {
    case categories
    case list(page: Int, perPage: Int)
    case detail(id: String)
    case query(categoryCode: String, providerCode: String, customerCode: String)
    case pay(billId: String, accountId: String, idempotencyKey: String)

    var path: String {
        switch self {
        case .categories:
            return "/v1/bills/categories"
        case .list:
            return "/v1/bills"
        case .detail(let id):
            return "/v1/bills/\(id)"
        case .query:
            return "/v1/bills/query"
        case .pay:
            return "/v1/bills/pay"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .categories, .list, .detail:
            return .get
        case .query, .pay:
            return .post
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .pay(_, _, let idempotencyKey):
            return ["Idempotency-Key": idempotencyKey]
        default:
            return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .query(let categoryCode, let providerCode, let customerCode):
            return [
                "category_code": categoryCode,
                "provider_code": providerCode,
                "customer_code": customerCode
            ]
        case .pay(let billId, let accountId, _):
            return ["bill_id": billId, "account_id": accountId]
        case .categories, .detail:
            return nil
        }
    }
}

enum RechargesEndpoint: APIEndpoint {
    case validate(phoneNumber: String, carrierCode: String, amountMinor: Int)
    case confirm(phoneNumber: String, carrierCode: String, amountMinor: Int, accountId: String, idempotencyKey: String)
    case detail(id: String)

    var path: String {
        switch self {
        case .validate:
            return "/v1/recharges/validate"
        case .confirm:
            return "/v1/recharges/confirm"
        case .detail(let id):
            return "/v1/recharges/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .detail:
            return .get
        case .validate, .confirm:
            return .post
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .confirm(_, _, _, _, let idempotencyKey):
            return ["Idempotency-Key": idempotencyKey]
        default:
            return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .validate(let phoneNumber, let carrierCode, let amountMinor):
            return [
                "phone_number": phoneNumber,
                "carrier_code": carrierCode,
                "amount_minor": amountMinor
            ]
        case .confirm(let phoneNumber, let carrierCode, let amountMinor, let accountId, _):
            return [
                "phone_number": phoneNumber,
                "carrier_code": carrierCode,
                "amount_minor": amountMinor,
                "account_id": accountId
            ]
        case .detail:
            return nil
        }
    }
}

enum SavingsEndpoint: APIEndpoint {
    case rates
    case products
    case open(accountId: String, tenorMonths: Int, principalMinor: Int, idempotencyKey: String)
    case listOrders
    case detail(id: String)

    var path: String {
        switch self {
        case .rates:
            return "/v1/savings/rates"
        case .products:
            return "/v1/savings/products"
        case .open:
            return "/v1/savings/open"
        case .listOrders:
            return "/v1/savings"
        case .detail(let id):
            return "/v1/savings/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .open:
            return .post
        default:
            return .get
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .open(_, _, _, let idempotencyKey):
            return ["Idempotency-Key": idempotencyKey]
        default:
            return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .open(let accountId, let tenorMonths, let principalMinor, _):
            return [
                "account_id": accountId,
                "tenor_months": tenorMonths,
                "principal_minor": principalMinor
            ]
        default:
            return nil
        }
    }
}

enum BeneficiariesEndpoint: APIEndpoint {
    case list(page: Int, perPage: Int)
    case create(nickname: String, bankCode: String, accountNo: String, holderName: String)
    case detail(id: String)
    case update(id: String, nickname: String?, isFavorite: Bool?)
    case delete(id: String)

    var path: String {
        switch self {
        case .list, .create:
            return "/v1/beneficiaries"
        case .detail(let id), .update(let id, _, _), .delete(let id):
            return "/v1/beneficiaries/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .detail:
            return .get
        case .create:
            return .post
        case .update:
            return .put
        case .delete:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .create(let nickname, let bankCode, let accountNo, let holderName):
            return [
                "nickname": nickname,
                "bank_code": bankCode,
                "account_no": accountNo,
                "holder_name": holderName
            ]
        case .update(_, let nickname, let isFavorite):
            var params: Parameters = [:]
            if let nickname { params["nickname"] = nickname }
            if let isFavorite { params["is_favorite"] = isFavorite }
            return params
        case .detail, .delete:
            return nil
        }
    }
}

enum MessagesEndpoint: APIEndpoint {
    case list(page: Int, perPage: Int)
    case markRead(id: String)

    var path: String {
        switch self {
        case .list:
            return "/v1/messages"
        case .markRead(let id):
            return "/v1/messages/\(id)/read"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:
            return .get
        case .markRead:
            return .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .markRead:
            return nil
        }
    }
}

enum ReportsEndpoint: APIEndpoint {
    case transactions(page: Int, perPage: Int, from: String?, to: String?, type: String?)
    case summary(from: String, to: String)

    var path: String {
        switch self {
        case .transactions:
            return "/v1/reports/transactions"
        case .summary:
            return "/v1/reports/summary"
        }
    }

    var method: HTTPMethod { .get }

    var parameters: Parameters? {
        switch self {
        case .transactions(let page, let perPage, let from, let to, let type):
            var params: Parameters = ["page": page, "per_page": perPage]
            if let from { params["from"] = from }
            if let to { params["to"] = to }
            if let type { params["type"] = type }
            return params
        case .summary(let from, let to):
            return ["from": from, "to": to]
        }
    }
}
