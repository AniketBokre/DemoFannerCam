//
//  LFLivePreview.h
//  LFLiveKit
//
//  Created by 倾慕 on 16/5/2.
//  Copyright © 2016年 live Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFLivePreview : UIView

- (void) prepareForUsing;
- (void) changeCameraPosition;
- (BOOL) changeBeauty;
- (void) startPublishingWithStreamURL: (NSString*) streamURL localVideoPath: (NSURL*) localURL;
- (void) stopPublishing;

@end
