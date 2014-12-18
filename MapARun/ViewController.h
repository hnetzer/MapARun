//
//  ViewController.h
//  ArrestsPlotter
//
//  Created by Henry Netzer on 9/6/12.
//  Copyright (c) 2012 Henry Netzer. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface ViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate> {

    IBOutlet UINavigationItem *navItem;
    IBOutlet MKMapView *mapView;
    
    BOOL startingPoint;
    BOOL inKM;
    NSInteger annotationCount;
    float totalDistance;
    CLLocationCoordinate2D prevLoc;
    
    CLLocationManager *locationManager;
    
}

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UINavigationItem *navItem;

- (IBAction)clearButtonPressed:(id)sender;
- (IBAction)milesToKmToggled:(id)sender;
- (IBAction)helpButtonPressed:(id)sender;
- (IBAction)zoomToCurrentLocation:(id)sender;


@end