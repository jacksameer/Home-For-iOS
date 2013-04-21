//
//  PSHCoverFeedViewController.m
//  SocialHome
//
//  Created by Kenny Tang on 4/14/13.
//  Copyright (c) 2013 corgitoergosum.net. All rights reserved.
//

#import "PSHCoverFeedViewController.h"
#import "PSHFacebookDataService.h"
#import "PSHCoverFeedPageViewController.h"
#import "PSHHomeButtonView.h"
#import "FeedItem.h"
#import "ItemSource.h"

@interface PSHCoverFeedViewController ()<UIPageViewControllerDataSource>

@property (nonatomic, strong) NSMutableArray * feedItemsArray;
@property (nonatomic, strong) UIPageViewController * feedsPageViewController;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;

@property (nonatomic, strong) PSHCoverFeedPageViewController * currentPagePageViewController;

@property (nonatomic, strong) PSHFacebookDataService * facebookDataService;

@property (nonatomic, weak) IBOutlet PSHHomeButtonView * homeButtonView;


@end

@implementation PSHCoverFeedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"MMMM d"];
    self.feedItemsArray = [@[] mutableCopy];
//    [self initHomeButton];
    
    NSArray * feedItemsArray = [FeedItem findAllSortedBy:@"createdTime" ascending:NO];
    if ([feedItemsArray count] > 0){
        [self.feedItemsArray removeAllObjects];
        [self.feedItemsArray addObjectsFromArray:feedItemsArray];
        [self initFeedsPageViewController];
        
        // reload
    }else{
        self.facebookDataService = [PSHFacebookDataService sharedService];
        [self.facebookDataService fetchFeed:^(NSArray *resultsArray, NSError *error) {
            NSLog(@"done...");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.feedItemsArray removeAllObjects];
                [self.feedItemsArray addObjectsFromArray:resultsArray];
                // reload page view controller
                [self initFeedsPageViewController];
            });
        }];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - init methods

- (void) initFeedsPageViewController {
    
    if (self.feedsPageViewController == nil){
        self.feedsPageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        self.feedsPageViewController.dataSource = self;
        [self addChildViewController:self.feedsPageViewController];
        [self.view addSubview:self.feedsPageViewController.view];
        [self.feedsPageViewController didMoveToParentViewController:self];
    }
    
    FeedItem * firstFeedItem = self.feedItemsArray[0];
    PSHCoverFeedPageViewController * currentPagePageViewController = [[PSHCoverFeedPageViewController alloc] init];
    currentPagePageViewController.feedType = firstFeedItem.type;
    currentPagePageViewController.messageLabelString = firstFeedItem.message;
    currentPagePageViewController.infoLabelString = [NSString stringWithFormat:@"%@ - %@", [self.dateFormatter stringFromDate:firstFeedItem.updatedTime], firstFeedItem.source.name];
    currentPagePageViewController.likesCount = [firstFeedItem.likesCount integerValue];
    currentPagePageViewController.commentsCount = [firstFeedItem.commentsCount integerValue];
    currentPagePageViewController.feedItemGraphID = firstFeedItem.graphID;
    currentPagePageViewController.feedType = firstFeedItem.type;
    currentPagePageViewController.currentIndex = 0;
    if (firstFeedItem.imageURL != nil){
        currentPagePageViewController.imageURLString = firstFeedItem.imageURL;
    }
    currentPagePageViewController.sourceName = firstFeedItem.source.name;
    currentPagePageViewController.sourceAvartarImageURL = firstFeedItem.source.imageURL;
    
    [self.feedsPageViewController setViewControllers:@[currentPagePageViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
    }];
    
    CGRect pageViewRect = self.view.bounds;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        pageViewRect = CGRectInset(pageViewRect, 40.0, 40.0);
    }
    self.feedsPageViewController.view.frame = pageViewRect;
    
    self.view.gestureRecognizers = self.feedsPageViewController.gestureRecognizers;
    
    
}

#pragma mark - UIPageViewController dataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    PSHCoverFeedPageViewController *currentViewController = (PSHCoverFeedPageViewController*) viewController;
    NSInteger currentIndex = currentViewController.currentIndex;
    
    // prev page
    if (currentIndex == 0){
        return nil;
    }else{
        NSInteger previousIndex = currentIndex - 1;
        FeedItem * previousFeedItem = self.feedItemsArray[previousIndex];
        PSHCoverFeedPageViewController * prevPageViewController = [[PSHCoverFeedPageViewController alloc] init];
        prevPageViewController.feedType = previousFeedItem.type;
        prevPageViewController.messageLabelString = previousFeedItem.message;
        prevPageViewController.infoLabelString = [NSString stringWithFormat:@"%@ - %@", [self.dateFormatter stringFromDate:previousFeedItem.updatedTime], previousFeedItem.source.name];
        prevPageViewController.likesCount = [previousFeedItem.likesCount integerValue];
        prevPageViewController.commentsCount = [previousFeedItem.commentsCount integerValue];
        prevPageViewController.feedItemGraphID = previousFeedItem.graphID;
        prevPageViewController.feedType = previousFeedItem.type;
        prevPageViewController.currentIndex = previousIndex;
        if (previousFeedItem.imageURL != nil){
            prevPageViewController.imageURLString = previousFeedItem.imageURL;
        }
        prevPageViewController.sourceName = previousFeedItem.source.name;
        prevPageViewController.sourceAvartarImageURL = previousFeedItem.source.imageURL;
        return prevPageViewController;
    }
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    PSHCoverFeedPageViewController *currentViewController = (PSHCoverFeedPageViewController*) viewController;
    NSInteger currentIndex = currentViewController.currentIndex;
    NSInteger nextIndex = currentIndex+1;
    
    if (currentIndex < [self.feedItemsArray count]-1){
        
        FeedItem * nextFeedItem = self.feedItemsArray[nextIndex];
        
        PSHCoverFeedPageViewController * nextPageViewController = [[PSHCoverFeedPageViewController alloc] init];
        nextPageViewController.feedType = nextFeedItem.type;
        nextPageViewController.messageLabelString = nextFeedItem.message;
        nextPageViewController.infoLabelString = [NSString stringWithFormat:@"%@ - %@", [self.dateFormatter stringFromDate:nextFeedItem.updatedTime], nextFeedItem.source.name];
        nextPageViewController.likesCount = [nextFeedItem.likesCount integerValue];
        nextPageViewController.commentsCount = [nextFeedItem.commentsCount integerValue];
        nextPageViewController.feedItemGraphID = nextFeedItem.graphID;
        nextPageViewController.feedType = nextFeedItem.type;
        nextPageViewController.currentIndex = nextIndex;
        if (nextFeedItem.imageURL != nil){
            nextPageViewController.imageURLString = nextFeedItem.imageURL;
        }
        nextPageViewController.sourceName = nextFeedItem.source.name;
        nextPageViewController.sourceAvartarImageURL = nextFeedItem.source.imageURL;
        
        return nextPageViewController;
        
        
    }else{
        return nil;
    }
    
    
    
    
    
    
    
//    PSHCoverFeedPageViewController *currentViewController = (PSHCoverFeedPageViewController*) viewController;
//    NSInteger currentIndex = currentViewController.currentIndex;
//    NSInteger updateCurrentIndex = currentIndex +1;
//    
//    // prev page
//    self.prevPagePageViewController = currentViewController;
//    
//    // current page
//    self.currentPagePageViewController = self.nextPagePageViewController;
//    
//    // next page
//    if (updateCurrentIndex == [self.feedItemsArray count]-1){
//        return nil;
//    }else{
//
//        FeedItem * nextFeedItem = self.feedItemsArray[updateCurrentIndex+1];
//        self.nextPagePageViewController.feedType = nextFeedItem.type;
//        self.nextPagePageViewController.messageLabelString = nextFeedItem.message;
//        self.nextPagePageViewController.infoLabelString = [NSString stringWithFormat:@"%@ - %@", [self.dateFormatter stringFromDate:nextFeedItem.updatedTime], nextFeedItem.source.name];
//        self.nextPagePageViewController.likesCount = [nextFeedItem.likesCount integerValue];
//        self.nextPagePageViewController.commentsCount = [nextFeedItem.commentsCount integerValue];
//        self.nextPagePageViewController.feedItemGraphID = nextFeedItem.graphID;
//        self.nextPagePageViewController.feedType = nextFeedItem.type;
//        self.nextPagePageViewController.currentIndex = updateCurrentIndex+1;
//        if (nextFeedItem.imageURL != nil){
//            self.nextPagePageViewController.imageURLString = nextFeedItem.imageURL;
//        }
//        self.nextPagePageViewController.sourceName = nextFeedItem.source.name;
//        self.nextPagePageViewController.sourceAvartarImageURL = nextFeedItem.source.imageURL;
//    }
//    return  self.nextPagePageViewController;
    
    
}

#pragma mark - home button

- (void)initHomeButton {
    
    FetchProfileSuccess fetchProfileSuccess =^(NSString * graphID, NSString * avartarImageURL, NSError * error){
        NSLog(@"graphID: %@", graphID);
        NSLog(@"avartarImageURL: %@", avartarImageURL);
        NSLog(@"error: %@", error);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage * profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:avartarImageURL]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.homeButtonView.homeButtonImageView.image = profileImage;
                [self.view bringSubviewToFront:self.self.homeButtonView];
            });
        });
    };
    PSHFacebookDataService * facebookDataService = [PSHFacebookDataService sharedService];
    [facebookDataService fetchOwnProfile:fetchProfileSuccess];
    
}


@end
