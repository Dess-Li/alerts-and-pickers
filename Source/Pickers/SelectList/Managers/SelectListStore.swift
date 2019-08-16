import Foundation

struct SelectListStore {
    
    /// Result Enum
    ///
    /// - Success: Returns Grouped By Alphabets SelectList Info
    /// - Error: Returns error
    public enum GroupedByAlphabetsFetchResults {
        case success(response: [String: [SelectListInfo]])
        case error(error: (title: String?, message: String?))
    }
    
    /// Result Enum
    ///
    /// - Success: Returns Array of SelectList Info
    /// - Error: Returns error
    public enum FetchResults {
        case success(response: [SelectListInfo])
        case error(error: (title: String?, message: String?))
    }
    
    public static func getInfo(jsonData: Array<Any>, completionHandler: @escaping (FetchResults) -> ()) {        
        var result: [SelectListInfo] = []
        for jsonObject in jsonData {
            guard let selectListObj = jsonObject as? Dictionary<String, Any> else { continue }
            guard let title = selectListObj["title"] as? String,
                let id = selectListObj["id"] as? String else {
                    continue
            }
            let leftImage = selectListObj["leftImage"] as? String
            let leftImageType = selectListObj["leftImageType"] as? String
            let new = SelectListInfo(title: title, id: id, datas: selectListObj["datas"] as Any, leftImage: leftImage, leftImageType: leftImageType)
            result.append(new)
        }
        return completionHandler(FetchResults.success(response: result))
    }
    
    public static func fetch(jsonData: Array<Any>, completionHandler: @escaping (GroupedByAlphabetsFetchResults) -> ()) {
        SelectListStore.getInfo(jsonData: jsonData) { result in
            switch result {
            case .success(let info):
                var data = [String: [SelectListInfo]]()
                
                info.forEach {
                    let selectListName = $0.title
                    let index = String(selectListName[selectListName.startIndex])
                    var value = data[index] ?? [SelectListInfo]()
                    value.append($0)
                    data[index] = value
                }
                
                data.forEach { key, value in
                    data[key] = value.sorted(by: { lhs, rhs in
                        return lhs.title < rhs.title
                    })
                }
                completionHandler(GroupedByAlphabetsFetchResults.success(response: data))
                
            case .error(let error):
                completionHandler(GroupedByAlphabetsFetchResults.error(error: error))
            }
        }
    }
}
