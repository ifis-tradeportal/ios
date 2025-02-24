//
//  AmendOrderViewController.m
//  tradeportal
//
//  Created by Nagarajan Sathish on 13/11/14.
//
//

#import "AmendOrderViewController.h"
#import "OrderBookViewController.h"
#import "OrderBookModel.h"

@interface AmendOrderViewController (){
    BOOL resultFound;
}

@property (strong, nonatomic) NSMutableData *buffer;
@property (strong, nonatomic) NSXMLParser *parser;
@property (strong, nonatomic) NSString *parseURL;
@property (strong, nonatomic) NSURLConnection *conn;

@end

@implementation AmendOrderViewController
@synthesize orderPrice,orderQty,matchQty,nQty,nPrice,spinner,buffer,parser,parseURL,conn,order,orderBook,amendView,orderBookDetails,saveChanges;
DataModel *dm;
NSInteger qty ;
NSInteger y ;
CGFloat price;
NSUserDefaults *getOrder;


#pragma mark - View Delegates

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setGroupingSeparator:@","];
    [numberFormatter setGroupingSize:3];
    [numberFormatter setUsesGroupingSeparator:YES];
    
    NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
    [priceFormatter setDecimalSeparator:@"."];
    [priceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [priceFormatter setMaximumFractionDigits:3];
    [priceFormatter setMinimumFractionDigits:3];
    
    self.view.backgroundColor=[UIColor clearColor];
    orderBookDetails.view.alpha=0.5f;
    //    spinner.center= CGPointMake( [UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height/2);
    //    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    //    [mainWindow addSubview:spinner];
    
    orderQty.text = [numberFormatter stringFromNumber:[NSNumber numberWithInt:[order.orderQty intValue]]];
    orderPrice.text = [priceFormatter stringFromNumber:[NSNumber numberWithDouble:[order.orderPrice doubleValue]]];
    matchQty.text = [numberFormatter stringFromNumber:[NSNumber numberWithInt:[order.qtyFilled intValue]]];
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    singleTapGestureRecognizer.cancelsTouchesInView = NO;
    [self.amendView addGestureRecognizer:singleTapGestureRecognizer];
    [self.view addGestureRecognizer:singleTapGestureRecognizer];
}

-(void)handleSingleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer{
    [self.view endEditing:YES];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    NSCharacterSet* numberCharSet;
    if (textField == nPrice) {
        numberCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *arrayOfString = [newString componentsSeparatedByString:@"."];
        if ([arrayOfString count] > 2 )
            return NO;
    }
    else{
        numberCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    }
    for (int i = 0; i < [string length]; ++i)
    {
        unichar c = [string characterAtIndex:i];
        if (![numberCharSet characterIsMember:c])
        {
            return NO;
        }
    }
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setGroupingSeparator:@","];
    [numberFormatter setGroupingSize:3];
    [numberFormatter setUsesGroupingSeparator:YES];
    
    NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
    [priceFormatter setGroupingSeparator:@","];
    [priceFormatter setGroupingSize:3];
    [priceFormatter setDecimalSeparator:@"."];
    [priceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [priceFormatter setMaximumFractionDigits:3];
    [priceFormatter setMinimumFractionDigits:3];
    
    if (textField == nQty) {
        nQty.text = [numberFormatter stringFromNumber:[NSNumber numberWithInt:[[nQty.text stringByReplacingOccurrencesOfString:@"," withString:@""]intValue]]];
    }
    if (textField == nPrice) {
        nPrice.text = [priceFormatter stringFromNumber:[NSNumber numberWithDouble:[nPrice.text doubleValue]]];
    }
}

#pragma mark - Dismiss View

- (IBAction)cancelAmend:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.view endEditing:YES];
    orderBookDetails.view.alpha = 1.0f;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.view endEditing:YES];
    return YES;
}

#pragma mark - Invoke Amend Service

- (IBAction)confirmAmend:(id)sender {
    saveChanges.enabled = false;
    qty = [[nQty.text stringByReplacingOccurrencesOfString:@"," withString:@"" ] integerValue];
    price = [[nPrice.text stringByReplacingOccurrencesOfString:@"," withString:@""]floatValue];
    NSString *qFilled = [matchQty.text stringByReplacingOccurrencesOfString:@"," withString:@""];
    NSString *oQty = [orderQty.text stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (!(qty == 0 && price == 0.0)) {
        if(qty == 0){
            qty = [oQty intValue];
        }
        if (price == 0.0) {
            price = [order.orderPrice doubleValue];
        }
        if (!(qty < [qFilled intValue] || qty > [oQty intValue])) {
            [self checkStatus];
        }
        else{
            UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:@"Invalid Quantity" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [toast show];
            saveChanges.enabled = YES;
            int duration = 1.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [toast dismissWithClickedButtonIndex:0 animated:YES];
            });
        }
    } else {
        UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:@"Please enter\n New Order Price or Quantity" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [toast show];
        int duration = 1.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
}

-(void)checkStatus{
    self.parseURL = @"checkStatus";
    NSString *soapRequest = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                             "<soap:Body>"
                             "<GetOrderStatus xmlns=\"http://OMS/\">"
                             "<UserSession>%@</UserSession>"
                             "<recID>%d</recID>"
                             "</GetOrderStatus>"
                             "</soap:Body>"
                             "</soap:Envelope>", dm.sessionID,[order.refNo intValue]];
//    NSLog(@"SoapRequest is %@" , soapRequest);
    NSString *urls = [NSString stringWithFormat:@"%@%s",dm.serviceURL,"op=GetOrderStatus"];
    NSURL *url =[NSURL URLWithString:urls];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req addValue:@"http://OMS/GetOrderStatus" forHTTPHeaderField:@"SOAPAction"];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapRequest length]];
    [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[soapRequest dataUsingEncoding:NSUTF8StringEncoding]];
    
    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    self.spinner.hidesWhenStopped=YES;
    [spinner startAnimating];
    if (conn) {
        buffer = [NSMutableData data];
    }
}

#pragma mark - Connection Delegates

-(void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response {
    [buffer setLength:0];
}
-(void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data {
    [buffer appendData:data];
}
-(void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error {
    UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:@"Connection Error..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [toast show];
    int duration = 1.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toast dismissWithClickedButtonIndex:0 animated:YES];
    });
    [spinner stopAnimating];
}
-(void) connectionDidFinishLoading:(NSURLConnection *) connection {
    //NSLog(@"\n\nDone with bytes %lu", (unsigned long)[buffer length]);
    NSMutableString *theXML =
    [[NSMutableString alloc] initWithBytes:[buffer mutableBytes]
                                    length:[buffer length]
                                  encoding:NSUTF8StringEncoding];
    [theXML replaceOccurrencesOfString:@"&lt;"
                            withString:@"<" options:0
                                 range:NSMakeRange(0, [theXML length])];
    [theXML replaceOccurrencesOfString:@"&gt;"
                            withString:@">" options:0
                                 range:NSMakeRange(0, [theXML length])];
//    NSLog(@"\n\nSoap Response is %@",theXML);
    [buffer setData:[theXML dataUsingEncoding:NSUTF8StringEncoding]];
    parser =[[NSXMLParser alloc]initWithData:buffer];
    [parser setDelegate:self];
    [parser parse];
   
}

#pragma mark - XML Parser

-(void) parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName
  namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName attributes:(NSDictionary *) attributeDict {
    
    //parse the data
    if ([parseURL isEqualToString:@"amendOrder"]){
        if([elementName isEqualToString:@"AmendOrderFixIncomeResult"]){
            resultFound=NO;
        }
        if ([elementName isEqualToString:@"z:row"]) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [orderBookDetails.navigationController popViewControllerAnimated:YES];
            [orderBook reloadTableData];
            [orderBook.view setNeedsDisplay];
            UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:@"Amend Order request sent Successfully!" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [toast show];
            int duration = 1.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [toast dismissWithClickedButtonIndex:0 animated:YES];
            });
            [spinner stopAnimating];
        }
    }else if ([parseURL isEqualToString:@"checkStatus"]){
        if([elementName isEqualToString:@"GetOrderStatusResult"]){
            resultFound=NO;
        }
        if ([elementName isEqualToString:@"z:row"]) {
            if([[attributeDict objectForKey:@"ORDER_STATUS"] isEqualToString:@"0"]
               ||[[attributeDict objectForKey:@"ORDER_STATUS"] isEqualToString:@"1"]
               ||[[attributeDict objectForKey:@"ORDER_STATUS"] isEqualToString:@"5"]){
                self.parseURL = @"amendOrder";
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                NSString *currentdate = [dateFormatter stringFromDate:[NSDate date]];
                [dateFormatter setDateFormat:@"yyyyMMdd"];
                NSString *expDate = [dateFormatter stringFromDate:[NSDate date]];

                NSString *type;
                if ([order.orderType isEqualToString:@"LIM"]) {
                    type = @"2";
                }
                NSString *data = [NSString stringWithFormat:@"OrderSize=%ld~OrderPrice=%f~ExpireDate=%@~OrderType=%@~TimeInForce=%@~LastUpdateTime=%@~RecID=%@~UpdateBy=%@~VoiceLog=~",(long)qty,price,expDate,type,@"0",currentdate,order.refNo,dm.userID];
                NSString *soapRequest = [NSString stringWithFormat:
                                         @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                                         "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                                         "<soap:Body>"
                                         "<AmendOrderFixIncome xmlns=\"http://OMS/\">"
                                         "<UserSession>%@</UserSession>"
                                         "<strData>%@</strData>"
                                         "<nVersion>%d</nVersion>"
                                         "</AmendOrderFixIncome>"
                                         "</soap:Body>"
                                         "</soap:Envelope>", dm.sessionID,data,0];
//                                NSLog(@"SoapRequest is %@" , soapRequest);
                NSString *urls = [NSString stringWithFormat:@"%@%s",dm.serviceURL,"op=AmendOrderFixIncome"];
                NSURL *url =[NSURL URLWithString:urls];
                NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
                [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [req addValue:@"http://OMS/AmendOrderFixIncome" forHTTPHeaderField:@"SOAPAction"];
                NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapRequest length]];
                [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
                [req setHTTPMethod:@"POST"];
                [req setHTTPBody:[soapRequest dataUsingEncoding:NSUTF8StringEncoding]];
                conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
                spinner.hidesWhenStopped=YES;
                [spinner startAnimating];
                if (conn) {
                    buffer = [NSMutableData data];
                }
                
            }
        }
    }
}

- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string {
    NSString *msg;
    BOOL flag=FALSE;
    if(!resultFound){
        if([[string substringToIndex:1] isEqualToString:@"R"]){
            msg = @"Some Technical Error...\nPlease Try again...";
            flag=TRUE;
        }
        else if([[string substringToIndex:1] isEqualToString:@"E  "]){
            //NSLog(@"E error");
            msg = @"User has logged on elsewhere!";
            [self dismissViewControllerAnimated:YES completion:nil];
            [orderBookDetails dismissViewControllerAnimated:YES completion:nil];
            [[orderBookDetails navigationController]popToRootViewControllerAnimated:YES];
            flag=TRUE;
        }
        else if([string isEqualToString:@"E E  Insert record to DB failed "]){
            //NSLog(@"E error");
            msg = @"Request Failed...\nPlease Try Again..!";
            [self dismissViewControllerAnimated:YES completion:nil];
            [orderBookDetails.navigationController popViewControllerAnimated:YES];
            [orderBook reloadTableData];
            [orderBook.view setNeedsDisplay];
            flag=TRUE;
        }
        if (flag) {
            
            UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [toast show];
            int duration = 1.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [toast dismissWithClickedButtonIndex:0 animated:YES];
            });
            
        }
        [spinner stopAnimating];
        resultFound=YES;
    }
}

@end
