//
//  TableViewController.swift
//  SO-33975355
//
//  Copyright © 2017 Xavier Schott
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

class TableViewController: UITableViewController {

    let count:Int = 15
    var cachedImages:[UIImage?]?
    var cachedUrls:[URL?]?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = CGFloat(250 + 8 + 8) // Maximum image height + margins
        tableView.rowHeight = UITableViewAutomaticDimension

        doRefreshAction(self)
    }

    // commons.wikimedia.org has a random file URL, which returns HTML
    func fetchRandomURL(_ indexPath: IndexPath) {
        if let url = URL(string: "https://commons.wikimedia.org/wiki/Special:Random/File") {
            let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(
                with: url, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
                    var validJpgURL = false
                    if let location = location {
                        if let data:Data = try? Data(contentsOf: location) {
                            if let text = String(data: data, encoding: String.Encoding.utf8){
                                // Rudimentary page scrubbing
                                let search = "class=\"fullImageLink\" id=\"file\"><a href=\""

                                if let searchStart = text.range(of: search) {
                                    let searchRange:Range = (searchStart.upperBound ..< text.index(searchStart.upperBound, offsetBy: 1024))
                                    if let matchEnd = text.range(of: ".jpg",
                                        options: .caseInsensitive, range:searchRange, locale: nil) {
                                            let fullRange:Range = (searchStart.upperBound ..< matchEnd.upperBound)
                                            let jpegPath:String = text.substring(with: fullRange)
                                            if let url = URL(string: jpegPath) {
                                                validJpgURL = true
                                                self.loadImage(url, indexPath: indexPath)
                                            }
                                    }
                                }
                            }
                        }
                    }

                    // Special:Random did not return a jpg image, start over
                    if !validJpgURL {
                        self.fetchRandomURL(indexPath)
                    }
            })
            downloadTask.resume()
        }
    }

    func loadImage(_ url: URL, indexPath: IndexPath) {
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url, completionHandler: {
            (location: URL?, response: URLResponse?, error: Error?) -> Void in
            var validImage = false
            if let location = location {
                if let data:Data = try? Data(contentsOf: location) {
                    if let image:UIImage = UIImage(data: data) {
                        validImage = true
                        self.cachedImages![indexPath.row] = image
                        self.cachedUrls![indexPath.row] = url
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.tableView.beginUpdates()
                            self.tableView.reloadRows(
                                at: [indexPath],
                                with: .fade)
                            self.tableView.endUpdates()
                        })
                    }
                }
            }

            // Image loading failed, start over
            if !validImage {
                self.fetchRandomURL(indexPath)
            }
        })
        downloadTask.resume()
    }

    @IBAction func doRefreshAction(_ sender: Any) {
        cachedImages = [UIImage?](repeating: nil, count: count)
        cachedUrls = [URL?](repeating:nil, count: count)
        for index in 0 ..< count {
            let indexPath = IndexPath(row: index, section: 0)
            fetchRandomURL(indexPath)
        }
    }
    
    //MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "imageTableViewCell") as! TableViewCell
        cell.leftImageView.image = cachedImages![indexPath.row]
        if let url = cachedUrls![indexPath.row] {
            cell.rightLabel.text = url.lastPathComponent
        } else {
            cell.rightLabel.text = "\(indexPath.row + 1)"
        }
        return cell
    }
}
