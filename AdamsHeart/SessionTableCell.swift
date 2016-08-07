//
//  SessionTableCell.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/15/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import UIKit


class SessionTableCell: UITableViewCell {
    static let padding: CGFloat = 8
    static let labelHeight: CGFloat = 15
    static var imageSize = CGSize(width: UIScreen.main.bounds.width - padding * 2, height: CGFloat(200))
    static var cellHeight: CGFloat = SessionTableCell.padding * 4 + SessionTableCell.labelHeight * 2 + SessionTableCell.imageSize.height
    private var chartImage: UIImageView!
    private var dateLabel: UILabel!
    private var statsLabel: UILabel!
    
    private static var dateTimeFormat: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "M/d/yyyy h:mm a"
        return df
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.white
        selectionStyle = .none
        
        chartImage = UIImageView(frame: CGRect.zero)
        contentView.addSubview(chartImage)
        
        dateLabel = UILabel(frame: CGRect.zero)
        contentView.addSubview(dateLabel)
        
        statsLabel = UILabel(frame: CGRect.zero)
        contentView.addSubview(statsLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dateLabel.frame = CGRect(
            x: SessionTableCell.padding, y: SessionTableCell.padding,
            width: frame.width - SessionTableCell.padding * 2, height: SessionTableCell.labelHeight)
        statsLabel.frame = CGRect(
            x: SessionTableCell.padding, y: SessionTableCell.padding * 2 + SessionTableCell.labelHeight,
            width: frame.width - SessionTableCell.padding * 2, height: SessionTableCell.labelHeight)
        chartImage.frame = CGRect(
            origin: CGPoint(x: SessionTableCell.padding, y: SessionTableCell.padding * 3 + SessionTableCell.labelHeight * 2),
            size: SessionTableCell.imageSize)
    }
    
    func setRecord(record: SessionMetadataMO) {
        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(record.timestampValue))
        dateLabel.text = SessionTableCell.dateTimeFormat.string(from: date)
        let stats = record.thresholdStats
        if stats != nil && stats!.num >= 10 {
            statsLabel.text = "mean \(stats!.mean) min \(stats!.min) max \(stats!.max) count \(stats!.num)"
        } else {
            statsLabel.text = "n/a"
        }
        let ss = SessionStorage.instance
        chartImage.image = UIImage(contentsOfFile: ss.chartImageURL(timestamp: record.timestampValue).path)
        setNeedsLayout() // TODO: is this necessary?
    }
}
