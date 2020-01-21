import Foundation

extension RawProvider {
    static var groupsJSON: String {
        """
        {
            "items": [
                {
                    "code": "DISCOVER",
                    "regex": "^(6[045]|62212[6-9]|6221[3-9][0-9]|622[2-8][0-9]{2}|6229[01][0-9]|62292[0-5])[0-9]*$"
                },
                {
                    "code": "MASTERCARD",
                    "regex": "^(5[0-5]|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]*$"
                },
                {
                    "code": "DINERS",
                    "regex": "^(2014|2149|30[059]|3[689])[0-9]*$"
                },
                {
                    "code": "UNIONPAY",
                    "regex": "^62[0-9]*$"
                },
                {
                    "code": "AMEX",
                    "regex": "^3[47][0-9]*$"
                },
                {
                    "code": "JCB",
                    "regex": "^35[0-9]*$"
                },
                {
                    "code": "VISA",
                    "regex": "^4[0-9]*$"
                }
            ]
        }
        """
    }
}
