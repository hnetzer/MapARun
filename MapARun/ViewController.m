//
//  ViewController.m
//  ArrestsPlotter
//
//  Created by Henry Netzer on 9/6/12.
//  Copyright (c) 2012 Henry Netzer. All rights reserved.
//

#include <math.h>
#include <CoreLocation/CoreLocation.h>

#import "ViewController.h"

#define DEG2RAD(degrees) (degrees * 0.01745327)
#define RADIUS_OF_EARTH 6378.1
#define METERS_PER_MILE 1609.344

@class LocationController;

@interface ViewController ()

@end

@implementation ViewController

@synthesize mapView;
@synthesize navItem;

// When the view loads
- (void)viewDidLoad
{
    startingPoint = YES;
    inKM = NO;
    annotationCount = 0;
    
    //setting the long press gesture to plot points
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressOnMap:)];
    lpgr.minimumPressDuration = .3;
    [mapView addGestureRecognizer:lpgr];
}


- (IBAction)zoomToCurrentLocation:(id)sender {
    
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    [locationManager startUpdatingLocation];
    [locationManager stopUpdatingLocation];
    CLLocation *location = [locationManager location];
    
    if(location == nil) {
        UIAlertView *alertPopUp = [[UIAlertView alloc] initWithTitle:@"Error" message: @"Your current location is not avaliable"delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        
        [alertPopUp show];
    } else {
        CLLocationCoordinate2D userLocation;
        userLocation.latitude = location.coordinate.latitude;
        userLocation.longitude = location.coordinate.longitude;
    
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(userLocation, METERS_PER_MILE, METERS_PER_MILE);
        MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];
        [mapView setRegion:adjustedRegion animated:YES];
    }
    
    
}

- (IBAction)clearButtonPressed:(id)sender {
    
    for (id<MKAnnotation> annotation in mapView.annotations) {
        [mapView removeAnnotation:annotation];
    }
    
    for (id<MKOverlay> overlay in mapView.overlays) {
        [mapView removeOverlay:overlay];
    }
    
    totalDistance = 0;
    annotationCount = 0;
    navItem.title = @"Pick a starting point..";
}

- (IBAction)helpButtonPressed:(id)sender {
    
    UIAlertView *alertPopUp = [[UIAlertView alloc] initWithTitle:@"Help" message: @"Hold a spot on the map to plot a point.  Tap twice to zoom in, or press Auto-Zoom to zoom to your current location."delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
    
    [alertPopUp show];
}


- (IBAction)milesToKmToggled:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    NSInteger index = [segmentedControl selectedSegmentIndex];
    NSString *myNewString;
    if (index == 1) {
        inKM = YES;
        if(annotationCount > 1) {
            myNewString = [NSString stringWithFormat:@"%.02f km", totalDistance];
            navItem.title = myNewString;
        }
    } else if(index == 0) {
        inKM = NO;
        if(annotationCount > 1) {
            float distInMiles = totalDistance * 0.621371;
            myNewString = [NSString stringWithFormat:@"%.02f miles", distInMiles];
            navItem.title = myNewString;
        }
    }
}

- (float)calcDistFromStart:(CLLocationCoordinate2D)start toFinish:(CLLocationCoordinate2D)finish {
    
    float distInKM = acos((cos(DEG2RAD(start.latitude))* cos(DEG2RAD(finish.latitude))*
                           cos((-1*DEG2RAD(finish.longitude))- (-1*DEG2RAD(start.longitude)))) +
                          (sin(DEG2RAD(start.latitude))* sin(DEG2RAD(finish.latitude)))) * RADIUS_OF_EARTH;
    
    return distInKM;
}


- (void)handleLongPressOnMap:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];
    
    if(annotationCount == 0) {
        
        prevLoc = touchMapCoordinate;
        totalDistance = 0;
        navItem.title = @"Pick your next point...";
        
        MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
        pa.coordinate = touchMapCoordinate;
        pa.title = [NSString stringWithFormat:@"Start"];
        [mapView addAnnotation:pa];
    } else {
        
        float distInKM = [self calcDistFromStart:prevLoc toFinish:touchMapCoordinate];
        
        totalDistance = totalDistance + distInKM;
        NSString *distanceText;
        
        if(inKM) {
            distanceText = [NSString stringWithFormat:@"%.02f km", totalDistance];
        } else {
            float distInMiles = totalDistance * 0.621371;
            distanceText = [NSString stringWithFormat:@"%.02f miles", distInMiles];
        }
        
        navItem.title = distanceText;
        
        
        CLLocationCoordinate2D *locations = malloc(sizeof(CLLocationCoordinate2D)*2);
        locations[0] = touchMapCoordinate;
        locations[1] = prevLoc;
        
        MKPolyline *routeLine = [MKPolyline polylineWithCoordinates:locations count:2];
        [mapView addOverlay:routeLine];
        
        free(locations);
    }

    annotationCount++;
    
    prevLoc = touchMapCoordinate;
}

# pragma mark MKMapViewDelegate 

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{
	
	if ([overlay isKindOfClass:[MKPolyline class]]) {
		MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
		polylineView.strokeColor = [UIColor blueColor];
		polylineView.lineWidth = 8;
        polylineView.alpha = 0.5;
		return polylineView;
	}
	return [[MKOverlayView alloc] initWithOverlay:overlay];
}

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id<MKAnnotation>)annotation
{
    if([annotation isKindOfClass: [MKUserLocation class]])
        return nil;
    
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[map dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
    if (pinView ==nil) {

        pinView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"Pin"];
        pinView.pinColor = MKPinAnnotationColorGreen;
        pinView.animatesDrop = NO;
        
    }
    return pinView;
}


@end
