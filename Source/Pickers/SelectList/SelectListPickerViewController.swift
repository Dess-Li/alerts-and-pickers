import UIKit

extension UIAlertController {

    /// Add ChinaBank Picker
    ///
    /// - Parameters:
    ///   - type: bankName, phoneCode
    ///   - action: for selected ChinaBank
    
    func addSelectListPicker(listData: Array<Any>, viewMode: Bool = false, selection: @escaping SelectListPickerViewController.Selection) {
        var info: SelectListInfo?
        let selection: SelectListPickerViewController.Selection = selection
        let buttonSelect: UIAlertAction = UIAlertAction(title: "Select", style: .default) { action in
            selection(info)
        }
        buttonSelect.isEnabled = false
        
        let vc = SelectListPickerViewController { new in
            info = new
            buttonSelect.isEnabled = new != nil
        }
        vc.listData = listData
        set(vc: vc)
        if !viewMode {
            addAction(buttonSelect)
        }
    }
}

final class SelectListPickerViewController: UIViewController {
    
    // MARK: UI Metrics
    
    struct UI {
        static let rowHeight = CGFloat(50)
        static let separatorColor: UIColor = UIColor.lightGray.withAlphaComponent(0.4)
    }
    
    // MARK: Properties
    
    public typealias Selection = (SelectListInfo?) -> Swift.Void
    public var listData: Array<Any> = []
    fileprivate var selection: Selection?
    
    fileprivate var orderedInfo = [String: [SelectListInfo]]()
    fileprivate var sortedInfoKeys = [String]()
    fileprivate var filteredInfo: [SelectListInfo] = []
    fileprivate var selectedInfo: SelectListInfo?
    
    //fileprivate var searchBarIsActive: Bool = false
    
    fileprivate lazy var searchView: UIView = UIView()
    
    fileprivate lazy var searchController: UISearchController = { [unowned self] in
        $0.searchResultsUpdater = self
        $0.searchBar.delegate = self
        $0.dimsBackgroundDuringPresentation = false
        /// true if search bar in tableView header
        $0.hidesNavigationBarDuringPresentation = true
        $0.searchBar.searchBarStyle = .minimal
        $0.searchBar.textField?.textColor = .black
        $0.searchBar.textField?.clearButtonMode = .whileEditing
        return $0
    }(UISearchController(searchResultsController: nil))
    
    fileprivate lazy var tableView: UITableView = { [unowned self] in
        $0.dataSource = self
        $0.delegate = self
        $0.rowHeight = UI.rowHeight
        $0.separatorColor = UI.separatorColor
        $0.bounces = true
        $0.backgroundColor = nil
        $0.tableFooterView = UIView()
        $0.sectionIndexBackgroundColor = .clear
        $0.sectionIndexTrackingBackgroundColor = .clear
        return $0
    }(UITableView(frame: .zero, style: .plain))
    
    fileprivate lazy var indicatorView: UIActivityIndicatorView = {
        $0.color = .lightGray
        return $0
    }(UIActivityIndicatorView(style: .whiteLarge))
    
    // MARK: Initialize
    
    required init(selection: @escaping Selection) {
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // http://stackoverflow.com/questions/32675001/uisearchcontroller-warning-attempting-to-load-the-view-of-a-view-controller/
        let _ = searchController.view
        Log("has deinitialized")
    }
    
    override func loadView() {
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(indicatorView)
        
        searchView.addSubview(searchController.searchBar)
        tableView.tableHeaderView = searchView
        
        //extendedLayoutIncludesOpaqueBars = true
        //edgesForExtendedLayout = .bottom
        definesPresentationContext = true
        
        tableView.register(SelectListTableViewCell.self, forCellReuseIdentifier: SelectListTableViewCell.identifier)
        
        updateInfo()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.tableHeaderView?.height = 57
        searchController.searchBar.sizeToFit()
        searchController.searchBar.frame.size.width = searchView.frame.size.width
        searchController.searchBar.frame.size.height = searchView.frame.size.height
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        indicatorView.center = view.center
        preferredContentSize.height = tableView.contentSize.height
    }
    
    func updateInfo() {
        indicatorView.startAnimating()
        
        SelectListStore.fetch(jsonData: self.listData) { [unowned self] result in
            switch result {
                
            case .success(let orderedInfo):
                let data: [String: [SelectListInfo]] = orderedInfo
                /*
                 switch self.type {
                 case .currency:
                 data = data.filter { i in
                 guard let code = i.currencyCode else { return false }
                 return ChinaBank.commonISOCurrencyCodes.contains(code)
                 }.sorted { $0.currencyCode < $1.currencyCode }
                 default: break }
                 */
                
                self.orderedInfo = data
                self.sortedInfoKeys = Array(self.orderedInfo.keys).sorted(by: <)
                
                DispatchQueue.main.async {
                    self.indicatorView.stopAnimating()
                    self.tableView.reloadData()
                }
                
            case .error(let error):
                
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(style: .alert, title: error.title, message: error.message)
                    alert.addAction(title: "OK", style: .cancel) { action in
                        self.indicatorView.stopAnimating()
                        self.alertController?.dismiss(animated: true)
                    }
                    alert.show()
                }
            }
        }
    }
    
    func sortFilteredInfo() {
        filteredInfo = filteredInfo.sorted { lhs, rhs in
            return lhs.title < rhs.title
        }
    }
    
    func info(at indexPath: IndexPath) -> SelectListInfo? {
        if searchController.isActive {
            return filteredInfo[indexPath.row]
        }
        let key: String = sortedInfoKeys[indexPath.section]
        if let info = orderedInfo[key]?[indexPath.row] {
            return info
        }
        return nil
    }
    
    func indexPathOfSelectedInfo() -> IndexPath? {
        guard let selectedInfo = selectedInfo else { return nil }
        if searchController.isActive {
            for row in 0 ..< filteredInfo.count {
                if filteredInfo[row].title == selectedInfo.title {
                    return IndexPath(row: row, section: 0)
                }
            }
        }
        for section in 0 ..< sortedInfoKeys.count {
            if let orderedInfo = orderedInfo[sortedInfoKeys[section]] {
                for row in 0 ..< orderedInfo.count {
                    if orderedInfo[row].title == selectedInfo.title {
                        return IndexPath(row: row, section: section)
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - UISearchResultsUpdating

extension SelectListPickerViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, searchController.isActive {
            filteredInfo = []
            if searchText.count > 0, let values = orderedInfo[String(searchText[searchText.startIndex])] {
                filteredInfo.append(contentsOf: values.filter { $0.title.hasPrefix(searchText) })
            } else {
                orderedInfo.forEach { key, value in
                    filteredInfo += value
                }
            }
            sortFilteredInfo()
        }
        tableView.reloadData()
        
        guard let selectedIndexPath = indexPathOfSelectedInfo() else { return }
        Log("selectedIndexPath = \(selectedIndexPath)")
        tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
    }
}

// MARK: - UISearchBarDelegate

extension SelectListPickerViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

    }
}

// MARK: - TableViewDelegate

extension SelectListPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let info = info(at: indexPath) else { return }
        selectedInfo = info
        selection?(selectedInfo)
    }
}

// MARK: - TableViewDataSource

extension SelectListPickerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive { return 1 }
        return sortedInfoKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive { return filteredInfo.count }
        if let infoForSection = orderedInfo[sortedInfoKeys[section]] {
            return infoForSection.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if searchController.isActive { return 0 }
        tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: .top , animated: false)
        return sortedInfoKeys.firstIndex(of: title)!
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive { return nil }
        return sortedInfoKeys
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive { return nil }
        return sortedInfoKeys[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let info = info(at: indexPath) else { return UITableViewCell() }
        
        let cell: UITableViewCell
        
        cell = tableView.dequeueReusableCell(withIdentifier: SelectListTableViewCell.identifier) as! SelectListTableViewCell
        cell.textLabel?.text = info.title
        
        cell.detailTextLabel?.textColor = .darkGray
        
        DispatchQueue.main.async {
            let size: CGSize = CGSize(width: 32, height: 24)
            switch info.leftImageType {
            case "assets":
                cell.imageView?.image = UIImage(named: info.leftImageType!)?.imageWithSize(size: size, roundedRadius: 3)
            case "url":
                let url = URL(string: info.leftImageType!)!
                let request = URLRequest(url: url)
                let session = URLSession.shared
                let dataTask = session.dataTask(with: request, completionHandler: {
                    (data, response, error) -> Void in
                    if error != nil{
                        print(error.debugDescription)
                    }else{
                        let img = UIImage(data:data!)
                        DispatchQueue.main.async {
                            cell.imageView?.image = img?.imageWithSize(size: size, roundedRadius: 3)
                        }
                        
                    }
                }) as URLSessionTask
                dataTask.resume()
            default: break
            }
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        if let selected = selectedInfo, selected.title == info.title {
            cell.isSelected = true
        }
        
        return cell
    }
}
