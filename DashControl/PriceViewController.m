//
//  PriceViewController.m
//  DashControl
//
//  Created by Manuel Boyer on 22/08/2017.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "PriceViewController.h"
#import "DCCoreDataManager.h"
#import "ChartDataEntry+CoreDataProperties.h"
#import "ChartTimeFormatter.h"

@interface PriceViewController ()


@property (nonatomic, strong) IBOutlet CandleStickChartView *chartView;
@property (nonatomic, strong) IBOutlet UIButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSArray *options;
@property (nonatomic, strong) Market * selectedMarket;
@property (nonatomic, strong) Exchange * selectedExchange;
@property (nonatomic, assign) ChartTimeInterval timeInterval;
@property (nonatomic, strong) NSDate * startTime;
@property (nonatomic, strong) NSDate * endTime;

@end

@implementation PriceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Candle Stick Chart";
    
    self.options = @[
                     @{@"key": @"toggleValues", @"label": @"Toggle Values"},
                     @{@"key": @"toggleIcons", @"label": @"Toggle Icons"},
                     @{@"key": @"toggleHighlight", @"label": @"Toggle Highlight"},
                     @{@"key": @"animateX", @"label": @"Animate X"},
                     @{@"key": @"animateY", @"label": @"Animate Y"},
                     @{@"key": @"animateXY", @"label": @"Animate XY"},
                     @{@"key": @"saveToGallery", @"label": @"Save to Camera Roll"},
                     @{@"key": @"togglePinchZoom", @"label": @"Toggle PinchZoom"},
                     @{@"key": @"toggleAutoScaleMinMax", @"label": @"Toggle auto scale min/max"},
                     @{@"key": @"toggleShadowColorSameAsCandle", @"label": @"Toggle shadow same color"},
                     @{@"key": @"toggleData", @"label": @"Toggle Data"},
                     ];
    
    _chartView.delegate = self;
    
    _chartView.chartDescription.enabled = NO;
    
    _chartView.maxVisibleCount = 60;
    _chartView.pinchZoomEnabled = NO;
    _chartView.drawGridBackgroundEnabled = NO;
    
    ChartTimeFormatter * chartTimeFormatter = [[ChartTimeFormatter alloc] init];
    
    NSInteger steps = [chartTimeFormatter stepsForChartTimeInterval:ChartTimeInterval_5Mins timeFrame:ChartTimeFrame_6H];
    
    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    xAxis.drawGridLinesEnabled = NO;
    //    xAxis.axisMinimum = 1;
    //    xAxis.axisMaximum = steps;
    //[xAxis setValueFormatter:dateFormatter];
    
    ChartYAxis *leftAxis = _chartView.leftAxis;
    leftAxis.labelCount = 7;
    leftAxis.drawGridLinesEnabled = NO;
    leftAxis.drawAxisLineEnabled = NO;
    
    ChartYAxis *rightAxis = _chartView.rightAxis;
    rightAxis.enabled = NO;
    
    _chartView.legend.enabled = NO;
    NSUserDefaults * standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults addObserver:self
                       forKeyPath:CURRENT_EXCHANGE_MARKET_PAIR
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
    if ([standardDefaults objectForKey:CURRENT_EXCHANGE_MARKET_PAIR]) {
        NSError * error = nil;
        NSDictionary * currentExchangeMarketPair = [standardDefaults objectForKey:CURRENT_EXCHANGE_MARKET_PAIR];
        Market * currentMarket = [[DCCoreDataManager sharedManager] marketNamed:[currentExchangeMarketPair objectForKey:@"market"] inContext:self.managedObjectContext error:&error];
        Exchange * currentExchange = error?nil:[[DCCoreDataManager sharedManager] exchangeNamed:[currentExchangeMarketPair objectForKey:@"exchange"] inContext:self.managedObjectContext error:&error];
        if (!error) {
            self.selectedMarket = currentMarket;
            self.selectedExchange = currentExchange;
            self.timeInterval = ChartTimeInterval_5Mins;
            self.startTime = [NSDate dateWithTimeIntervalSinceNow:-[ChartTimeFormatter timeIntervalForChartTimeFrame:ChartTimeFrame_6H]];
            self.endTime = nil;
            [self updateChartData];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context
{
    if([keyPath isEqual:CURRENT_EXCHANGE_MARKET_PAIR])
    {
        NSLog(@"SomeKey change: %@", change);
    }
}

- (void)updateChartData
{
    if (self.shouldHideData)
    {
        _chartView.data = nil;
        return;
    }
    NSError * error = nil;
    NSArray * chartData = [[DCCoreDataManager sharedManager] fetchChartDataForExchangeIdentifier:self.selectedExchange.identifier        forMarketIdentifier:self.selectedMarket.identifier interval:self.timeInterval startTime:self.startTime endTime:self.endTime inContext:self.managedObjectContext error:&error] ;
    if (!error) {
        NSMutableArray *charDataPoints = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < chartData.count; i++)
        {
            ChartDataEntry * entry = [chartData objectAtIndex:i];
            
            [charDataPoints addObject:[[CandleChartDataEntry alloc] initWithX:i shadowH:entry.high shadowL:entry.low open:entry.open close:entry.close icon: [UIImage imageNamed:@"icon"]]];
        }
        
        CandleChartDataSet *set1 = [[CandleChartDataSet alloc] initWithValues:charDataPoints label:@"Data Set"];
        set1.axisDependency = AxisDependencyLeft;
        [set1 setColor:[UIColor colorWithWhite:80/255.f alpha:1.f]];
        
        set1.drawIconsEnabled = NO;
        
        set1.shadowColor = UIColor.darkGrayColor;
        set1.shadowWidth = 0.7;
        set1.decreasingColor = [UIColor colorWithRed:164/255.f green:32/255.f blue:21/255.f alpha:1.f];
        set1.decreasingFilled = YES;
        set1.increasingColor = [UIColor colorWithRed:51/255.f green:147/255.f blue:73/255.f alpha:1.f];
        set1.increasingFilled = YES;
        set1.neutralColor = UIColor.blueColor;
        
        CandleChartData *data = [[CandleChartData alloc] initWithDataSet:set1];
        
        _chartView.data = data;
    }
}

#pragma mark - Common option actions

- (void)handleOption:(NSString *)key forChartView:(ChartViewBase *)chartView
{
    if ([key isEqualToString:@"toggleValues"])
    {
        for (id<IChartDataSet> set in chartView.data.dataSets)
        {
            set.drawValuesEnabled = !set.isDrawValuesEnabled;
        }
        
        [chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleIcons"])
    {
        for (id<IChartDataSet> set in chartView.data.dataSets)
        {
            set.drawIconsEnabled = !set.isDrawIconsEnabled;
        }
        
        [chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleHighlight"])
    {
        chartView.data.highlightEnabled = !chartView.data.isHighlightEnabled;
        [chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"animateX"])
    {
        [chartView animateWithXAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"animateY"])
    {
        [chartView animateWithYAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"animateXY"])
    {
        [chartView animateWithXAxisDuration:3.0 yAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"saveToGallery"])
    {
        UIImageWriteToSavedPhotosAlbum([chartView getChartImageWithTransparent:NO], nil, nil, nil);
    }
    
    if ([key isEqualToString:@"togglePinchZoom"])
    {
        BarLineChartViewBase *barLineChart = (BarLineChartViewBase *)chartView;
        barLineChart.pinchZoomEnabled = !barLineChart.isPinchZoomEnabled;
        
        [chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleAutoScaleMinMax"])
    {
        BarLineChartViewBase *barLineChart = (BarLineChartViewBase *)chartView;
        barLineChart.autoScaleMinMaxEnabled = !barLineChart.isAutoScaleMinMaxEnabled;
        
        [chartView notifyDataSetChanged];
    }
    
    if ([key isEqualToString:@"toggleData"])
    {
        _shouldHideData = !_shouldHideData;
        [self updateChartData];
    }
    
    if ([key isEqualToString:@"toggleBarBorders"])
    {
        for (id<IBarChartDataSet, NSObject> set in chartView.data.dataSets)
        {
            if ([set conformsToProtocol:@protocol(IBarChartDataSet)])
            {
                set.barBorderWidth = set.barBorderWidth == 1.0 ? 0.0 : 1.0;
            }
        }
        
        [chartView setNeedsDisplay];
    }
}


- (void)optionTapped:(NSString *)key
{
    if ([key isEqualToString:@"toggleShadowColorSameAsCandle"])
    {
        for (id<ICandleChartDataSet> set in _chartView.data.dataSets)
        {
            set.shadowColorSameAsCandle = !set.shadowColorSameAsCandle;
        }
        
        [_chartView notifyDataSetChanged];
        return;
    }
    
    [self handleOption:key forChartView:_chartView];
}

#pragma mark - Actions

-(IBAction)chooseInterval:(id)sender {
    self.timeInterval = [((UISegmentedControl*)sender) selectedSegmentIndex];
    [self updateChartData];
}

-(IBAction)chooseTimeFrame:(id)sender {
    ChartTimeFrame chartTimeFrame = [((UISegmentedControl*)sender) selectedSegmentIndex];
    NSTimeInterval timeFrame = [ChartTimeFormatter timeIntervalForChartTimeFrame:chartTimeFrame];
    self.startTime = [NSDate dateWithTimeIntervalSinceNow:-timeFrame];
    [self updateChartData];
}

#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull)entry highlight:(ChartHighlight * __nonnull)highlight
{
    NSLog(@"chartValueSelected");
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}

@end
