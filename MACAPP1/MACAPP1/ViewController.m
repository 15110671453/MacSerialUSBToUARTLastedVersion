//
//  ViewController.m
//  MACAPP1
//
//  Created by admindyn on 2018/3/23.
//  Copyright © 2018年 admindyn. All rights reserved.
//
#import <CoreFoundation/CoreFoundation.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
#import "ViewController.h"

#define POLY 0xa001

@interface ViewController()<ORSSerialPortDelegate>

@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;


@property (nonatomic) BOOL shouldAddLineEnding;

@property (nonatomic) BOOL rateSelectedYN;

@property (nonatomic) BOOL canHandleNewData;

@property(nonatomic,unsafe_unretained)  char* dataP;

@end


@implementation ViewController

/*
 
 char m;
 scanf(" %c",&m); //前面加空格是为了去掉空格、回车等操作
 NSLog(@"the character is %c",m);
 
 上面这个程序是各位比较熟悉的两个方法一个输入、一个输出，但是如果我改一下改成
 
 char *m;
 NSLog(@"\n请输入一个字符");
 scanf(" %c",m);
 NSLog(@"\nthis is %c",*m);
 
 是否正确呢，编译时是否会报错，运行时是否会出问题？
 其实这个程序，如果编译的时候不会出现异常，但是如果运行的话，会出现运行时异常（出现lldb命令，使用kill命令结束即可），原因是就是我们定义了一个char指针m，这个指针没有进行初始化赋值，导致程序运行时无法找到存储这个字符的内存空间，如果改成malloc  就可以
 
 这就是什么时候该malloc 就是 指针必须 不能只定义 不初始化
 
 
 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    NSArray * rates =@[@"300", @"1200", @"2400", @"4800", @"9600", @"14400", @"19200", @"28800", @"38400", @"57600", @"115200", @"230400"];
    
    [self.rateSelected addItemsWithTitles:rates];
    self.serialPortManager =[ORSSerialPortManager sharedSerialPortManager];
    
   
    
    [self.devicesSelected removeAllItems];
     NSArray* arr= [_serialPortManager availablePorts];
    for (int i =0; i<[arr count]; i++) {
        ORSSerialPort* obj = [arr objectAtIndex:i];
        [self.devicesSelected addItemWithTitle:obj.name];
        
        
    }
    
    
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
    [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
    
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
    
    
}


#pragma mark 发送的数据 是否追加字符串结束符


- (NSString *)lineEndingString
{
    NSDictionary *map = @{@0: @"\r", @1: @"\n", @2: @"\r\n"};
    NSString *result = map[@(self.lindEnding.selectedTag)];
    return result ?: @"\n";
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)sendAction:(id)sender {
    if (self.serialPort) {
        if (!self.canHandleNewData) {
            if (!self.rateSelectedYN) {
                self.serialPort.baudRate = @9600;
            }
            NSString *string = self.sendTextField.stringValue;
            if (self.shouldAddLineEnding && ![string hasSuffix:[self lineEndingString]]) {
                string = [string stringByAppendingString:[self lineEndingString]];
            }
            
            
            unsigned char* dataPs= [self readyData:string];
            
            NSData *dataToSend =[NSData dataWithBytes:dataPs length:strlen(dataPs)];
            
          
            self.canHandleNewData = YES;
            
            [self.serialPort sendData:dataToSend];
        }
        
    }
   
}

-(unsigned char*)readyData:(NSString*)dataStr
{
    
    uint8_t qiandao = 0xFF;
    uint8_t qishi[2];
    qishi[0] = 0xFF;
    qishi[1] = 0xAA;
    uint8_t fasongConfirmed = 0x07;
    uint8_t fasongNOConfirmed = 0x08;
    uint8_t duquDeviceSate = 0x03;
    
    /*
     需要 准备命令字
     */
    uint8_t command =fasongNOConfirmed|0xC0;
    /*
     发送的数据报文的长度
     */
    
    
    
    
    const  char* data = [dataStr cStringUsingEncoding:NSASCIIStringEncoding] ;
 
    
    size_t s = strlen(data);
     uint8_t length = 0x00;
    if (s>0xff) {
        printf("字符串长度超过一个字节");
        return "system update it";
    }
    length = s;
   
    
   
    uint32_t crc = ModBusCRC((unsigned char*)data, length);
    
    uint8_t end = 0x40;
    int sum = sizeof(qiandao)+sizeof(qishi)+sizeof(command)+sizeof(length)+sizeof(data)+sizeof(crc)+sizeof(end)+length;
    if (!_dataP) {
      self.dataP = malloc(sum*sizeof(char));
        memset(_dataP, 0, sizeof(sum*sizeof(char)));
    }else
    {
        memset(_dataP, 0, sizeof(sum*sizeof(char)));
        
    }
    
    char* start =_dataP ;
    snprintf(_dataP, 8,"%x", qiandao);
    _dataP = _dataP + 2;
    snprintf(_dataP, 8,"%x", qishi[0]);
    _dataP = _dataP + 2;
    snprintf(_dataP, 8,"%x", qishi[1]);
    _dataP = _dataP + 2;
    snprintf(_dataP, 8,"%2x", command);
    _dataP = _dataP + 2;
    snprintf(_dataP, 8,"%2x", length);
    _dataP = _dataP + 2;
    
    strcpy(_dataP, (char*)data);
    _dataP= _dataP + length;
    
    snprintf(_dataP, 8, "%x",crc);
    
    _dataP= _dataP + 4;
    
    snprintf(_dataP++, 8, "%x",end);
    
    return (unsigned char*)start;
    
}
unsigned short ModBusCRC(unsigned char *buf,unsigned int lenth) {
   
    int i,j;
    
    unsigned short crc;
    
    for(i=0,crc=0xffff;i< lenth;i++) {
        
        crc ^= buf[i];
        
        for(j=0;j<8;j++) {
            if(crc&0x01)
            {
                crc = (crc >> 1) ^ POLY;
            }
            else{
                crc >>= 1;
            }
        }
        
        return crc;
    }
    
    return "";
}
-(void)setSerialPort:(ORSSerialPort *)serialPort
{
#pragma mark 切换串口设备
    if (serialPort != _serialPort)
    {
        [_serialPort close];
        _serialPort.delegate = nil;
        
        _serialPort = serialPort;
        
        _serialPort.delegate = self;
    }
    
}
#pragma mark 打开串口连接或关闭
- (IBAction)openOrClosePort:(id)sender {
    
    if (self.serialPort) {
        if (!self.rateSelectedYN) {
            self.serialPort.baudRate = @9600;
        }
         self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
      
    }else
    {
        
        NSArray* arr= [_serialPortManager availablePorts];
        self.serialPort = [arr objectAtIndex:0];
        self.serialPort.baudRate = @9600;
        self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
        
        
    }
   
    
}

- (IBAction)cleartAC:(id)sender {
    
    self.contentTV.string = @"";
    
}
- (IBAction)deviceSelectedAc:(id)sender {
    NSArray* arr= [_serialPortManager availablePorts];
    for (int i =0; i<[arr count]; i++) {
        ORSSerialPort* obj = [arr objectAtIndex:i];
        
        NSPopUpButton* mes =(NSPopUpButton*)sender;
        NSMenuItem* selected = mes.selectedItem;
        if ([obj.name isEqualToString:selected.title]) {
            
            
            [self setSerialPort:obj];
            return;
        }
        
        
    }
}

- (IBAction)rateSelectedAc:(id)sender {
     NSArray * rates =@[@300, @1200, @2400, @4800, @9600, @14400, @19200, @28800, @38400, @57600, @115200, @230400];
    if (!self.rateSelectedYN) {
        self.rateSelectedYN=YES;
    }
    for (int i =0; i<[rates count]; i++) {
        NSNumber* obj = [rates objectAtIndex:i];
        
        NSPopUpButton* mes =(NSPopUpButton*)sender;
      
        NSInteger tag = mes.selectedTag;
        if (i==tag) {
            
            if (self.serialPort) {
               self.serialPort.baudRate = obj;
            }else
            {
                
                NSLog(@"请先选择串口设备");
                
            }
            
            return;
        }
        
        
    }
    
}

#pragma mark - ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    self.openOrClose.title = @"Close";
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    self.openOrClose.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    
    /*
     十六进制字符串 转换为 asc码值串
     
     http://www.ab126.com/goju/1711.html
     */
    
    
    uint8_t* buffer = (uint8_t*)[data bytes];
    NSUInteger length = data.length;
    if (self.canHandleNewData) {
        do {
            if (length==0) {
                printf("buffer 取完了\n");
                break;
            }
            if (*buffer == 0xff) {
                printf("开始处理返回的消息:\n");
            }
            
               
                NSString* cstr =[NSString localizedStringWithFormat:@"%.2x",*buffer ];
                
                NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                if ([string length] == 0) return;
                
                [self.contentTV.textStorage.mutableString appendString:string];
                [self.cStrContent.textStorage.mutableString appendString:cstr];
                
                [self.contentTV setNeedsDisplay:YES];
                [self.cStrContent setNeedsDisplay:YES];
                if (*buffer == 0x40) {
                    printf("%x",*buffer++);
                    printf("返回消息体结束\n");
                    printf("\n");
                    self.canHandleNewData=NO;
                    break;
                }
                printf("%x",*buffer++);
                length--;
            
            
        } while (length!=0);
    }
   
 
   
  
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
    self.openOrClose.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
}
#pragma mark NotificationDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [center removeDeliveredNotification:notification];
    });
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#endif

#pragma mark - Notifications

- (void)serialPortsWereConnected:(NSNotification *)notification
{
    NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
    NSLog(@"Ports were connected: %@", connectedPorts);
    [self postUserNotificationForConnectedPorts:connectedPorts];
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
    NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in connectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in disconnectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}


@end
