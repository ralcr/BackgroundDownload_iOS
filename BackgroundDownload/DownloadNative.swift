//
//  DownloadNative.swift
//  BackgroundDownload
//
//  Created by Cristian Baluta on 07/05/2019.
//  Copyright © 2019 Imagin soft. All rights reserved.
//

import UIKit

class DownloadNative: NSObject {

    var onProgress: ((Float, String) -> Void)?

    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "ro.imagin.background.urlsession")
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var task: URLSessionDownloadTask?

    func startDownload(_ url: String, resumeData: Data?) {
        if let resumeData = resumeData {
            task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            task = downloadsSession.downloadTask(with: URL(string: url)!)
        }
        task!.resume()
    }

    func resumeDownload() {
        let _ = downloadsSession
    }
}


extension DownloadNative: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 1
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        // 2
        let destinationURL = documentsPath.appendingPathComponent(sourceURL.lastPathComponent)
        print(destinationURL)
        // 3
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)
        try? fileManager.copyItem(at: location, to: destinationURL)
    }

    // Updates progress info
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        // 4
        DispatchQueue.main.async {
            self.onProgress?(progress, totalSize)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if  let urlString = (error as NSError?)?.userInfo["NSErrorFailingURLStringKey"] as? String,
            let resumedata = (error as NSError?)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            print(">>>>>>> Found resume data for url \(urlString)")
            startDownload(urlString, resumeData: resumedata)
        }
    }
}

extension DownloadNative: URLSessionDelegate {
    // Standard background session handler
    func urlSessionDidFinishEvents (forBackgroundURLSession session: URLSession) {
        print(">>>>>>> urlSessionDidFinishEvents")
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
}
