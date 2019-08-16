import UIKit

public struct SelectListInfo {
    
    public var title: String
    public var leftImage: String?
    public var leftImageType: String?
    public var id: String
    public var datas: Any
    
    init(title: String, id: String, datas: Any, leftImage: String?, leftImageType: String?) {
        self.title = title
        self.id = id
        self.datas = datas
        self.leftImage = leftImage
        self.leftImageType = leftImageType
    }
}
