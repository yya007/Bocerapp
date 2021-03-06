//
//  SignInViewController.swift
//  BocerApp
//
//  Created by Dempsy on 6/22/16.
//  Copyright © 2016 Dempsy. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate, NSURLConnectionDataDelegate, FBSDKLoginButtonDelegate{

    private var mNavBar: UINavigationBar?
    private let base = baseClass()
    private let userInfo = UserInfo()
    private let checkEmail = checkEmailForm()
    private let signInRequest = serverConn()
    private var firstName: String? = nil
    private var lastName: String? = nil
    private var imageString: String = ""
    private var dataChunk = NSMutableData()
    @IBOutlet private weak var mNavItem: UINavigationItem!
    @IBOutlet private weak var emailTF: HoshiTextField!
    @IBOutlet private weak var passwordTF: HoshiTextField!
    @IBOutlet private weak var signInBtn: UIButton!
    @IBOutlet private weak var resetPasswordBtn: UIButton!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
 
    private var email: String?
    private var password: String?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    //bugfix - July, 6th. Dempsy
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //设置导航栏
        let screenMaxX = UIScreen.mainScreen().bounds.maxX
        mNavBar = UINavigationBar(frame: CGRectMake(0,0,screenMaxX,54))
        mNavBar?.translucent = true
        mNavBar?.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        mNavBar?.shadowImage = UIImage()
        mNavBar?.backgroundColor = usefulConstants().defaultColor
        
        //设置状态栏颜色
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        let navTitleAttribute: NSDictionary = NSDictionary(object: UIColor.whiteColor(), forKey: NSForegroundColorAttributeName)
        mNavBar?.titleTextAttributes = navTitleAttribute as? [String : AnyObject]
        
        self.view.addSubview(mNavBar!)
        mNavBar?.pushNavigationItem(onMakeNavitem(), animated: true)
        
        //设置按键圆角
        signInBtn.layer.cornerRadius = usefulConstants().buttonCornerRadius
        
        //delgate & customize text field
        emailTF.delegate = self
        emailTF.borderActiveColor = .blueColor()
        emailTF.borderInactiveColor = .grayColor()
        emailTF.placeholderColor = .grayColor()
        passwordTF.delegate = self
        passwordTF.borderInactiveColor = .grayColor()
        passwordTF.borderActiveColor = .redColor()
        passwordTF.placeholderColor = .grayColor()
        //facebook stuff
        if (FBSDKAccessToken.currentAccessToken() != nil)
        {
            // User is already logged in, do work such as go to next view controller.
        }
        else
        {
            let loginView : FBSDKLoginButton = FBSDKLoginButton()
            self.view.addSubview(loginView)
            loginView.frame = CGRect(x: self.view.center.x - 125, y: self.view.frame.size.height - 60, width: 250, height: 40)
            loginView.readPermissions = ["public_profile", "email", "user_friends"]
            loginView.delegate = self
        }
        
        //增加右滑返回
        //addSwipeRecognizer()
        self.navigationController!.interactivePopGestureRecognizer!.enabled = true
    }
    
    //右滑返回
    @objc private func returnToFatherView() {
            self.navigationController?.popViewControllerAnimated(true)
    }
    
    private func addSwipeRecognizer() {
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(SignInViewController.returnToFatherView))
        swipeRecognizer.direction = .Right
        swipeRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(swipeRecognizer)
    }
    
    //按空白区域键盘回收
    @IBAction func viewClicked(sender: AnyObject) {
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
    }

    //text field close
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        resignFirstResponder()
        if textField == emailTF {
            passwordTF.becomeFirstResponder()
        } else {
            signInPerformed()
        }
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //设置导航栏左侧按键的action
    @objc private func onCancel(){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //创建一个导航项
    private func onMakeNavitem()->UINavigationItem{
        let backBtn = UIBarButtonItem(title: "ㄑBack", style: .Plain,
                                      target: self, action: #selector(SignInViewController.onCancel))
        backBtn.tintColor = UIColor.whiteColor()
        mNavItem.title = "SIGN IN"
        mNavItem.setLeftBarButtonItem(backBtn, animated: true)
        return mNavItem
    }
    
    //检测phone number和password的正确性
    private func checkValidation(number: String?, password: String?) -> Bool {
        if (number == nil || number == "") {
            let alertController = UIAlertController(title: "Warning",
                                                    message: "Email address cannot be empty", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return false
        }
        
        if (password == nil || password == "") {
            let alertController = UIAlertController(title: "Warning",
                                                    message: "Password cannot be empty", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return false
        }
        
        if (checkEmail.check(number) == false) {
            let alertController = UIAlertController(title: "Warning",
                                                    message: "Incorrect Email address form", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return false
        }
        
        return true
        
    }
    
    private func signInPerformed() {
        email = emailTF.text
        password = passwordTF.text?.md5()
        if (checkValidation(email, password: password)) {
            //TODO: 询问用户名和密码匹不匹配
            let dataString = NSString.localizedStringWithFormat("{\"username\":\"%@\",\"password\":\"%@\"}",email!,password!)
            let sent = NSData(data: dataString.dataUsingEncoding(NSASCIIStringEncoding)!)
            let dataLength = NSString.localizedStringWithFormat("%ld", sent.length)
            let path = usefulConstants().domainAddress + "/login"
            let url = NSURL(string: path)
            print("login request address: \(path)\n")
            let request = NSMutableURLRequest()
            request.URL = url
            request.HTTPMethod = "POST"
            request.setValue(dataLength as String, forHTTPHeaderField: "Content-Length")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = sent
            
            let conn = NSURLConnection(request: request, delegate: self, startImmediately: true)
            indicator.alpha = 1
            indicator.startAnimating()
            if (conn == nil) {
                let alertController = UIAlertController(title: "Warning",
                                                        message: "Connection Failure.", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func requestUserBasicInfo() {
        userInfo.setEmail(email!)
        let dataString = NSString.localizedStringWithFormat("{\"username\":\"%@\"}",email!)
        let sent = NSData(data: dataString.dataUsingEncoding(NSASCIIStringEncoding)!)
        let dataLength = NSString.localizedStringWithFormat("%ld", sent.length)
        let path = usefulConstants().domainAddress + "/retrieveUserInfo"
        let url = NSURL(string: path)
        print("userbasicinfo request address is \(path)\n")
        let request = NSMutableURLRequest()
        request.URL = url
        request.HTTPMethod = "POST"
        request.setValue(dataLength as String, forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = sent
        let conn = NSURLConnection(request: request, delegate: self, startImmediately: true)
        if (conn == nil) {
            let alertController = UIAlertController(title: "Warning",
                                                    message: "Connection Failure.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            
            print("cannot connect to the server\n")
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        dataChunk = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        dataChunk.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        let backmsg: AnyObject! = try! NSJSONSerialization.JSONObjectWithData(dataChunk, options: NSJSONReadingOptions(rawValue: 0))
        print("back msg is \(backmsg)")
        let targetAction = backmsg.objectForKey("Target Action") as! String?
        let content = backmsg.objectForKey("content") as! String?
        indicator.stopAnimating()
        indicator.alpha = 0
        print("back message is \(backmsg)")
        //普通登录
        if targetAction == "loginresult" {
            if content == "success" {
                //获取用户其他信息
                requestUserBasicInfo()
                
                print("login success\n")
            }
            else if content == "wrong" {
                let alertController = UIAlertController(title: "Warning",
                                                        message: "Wrong email and password combination.", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                
                print("wrong email and password combination\n")
            } else {
                let alertController = UIAlertController(title: "Warning",
                                                        message: "Connection Failure.", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                
                print("connection fails when trying email login")
            }
        }
        //facebook登录
        else if targetAction == "facebookresult" {
            if content == "success" {
                //获取用户其他信息
                requestUserBasicInfo()
                
                print("facebook login success\n")
            }
            else if content == "not exist" {
                //TODO: 进入facebook login ---有待商榷
                
                print("facebook account not exists")
            } else {
                let alertController = UIAlertController(title: "Warning",
                                                        message: "Connection Failure.", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                
                print("connection fails when trying facebook login")
            }
        }
        //user info
        else if ((targetAction == "userbasicinfo") || (targetAction == nil)) {
            if content == "fail" {
                let alertController = UIAlertController(title: "Warning",
                                                        message: "Server Issues.", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                
                print("Server downs when trying to get user basic info\n")
            } else {
//                firstName = backmsg.objectForKey("firstname") as! String?
//                lastName = backmsg.objectForKey("lastname") as! String?
//                let temp = backmsg.objectForKey("profileImage") 
//                if ((temp?.isEqual(NSNull)) != nil)  {
//                    imageString = nil
//                } else {
//                    imageString = backmsg.objectForKey("profileImage") as! String?
//                }
                print("\(backmsg)")
                let bodydata = backmsg.objectForKey("body") as! NSDictionary
                print("body data is \(bodydata)")
                firstName = bodydata["firstname"] as! NSString as String
                lastName = bodydata["lastname"] as! NSString as String
                let temp = bodydata["profileImage"] as! NSString? as String?
                print("\(temp)")
                if (temp == nil)  {
                    imageString = ""
                } else {
                    imageString = temp!
                }
                //TODO: 进入主界面
                userInfo.setName(firstName!, mLast: lastName!)
                userInfo.setImageString(imageString)
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let vc = appDelegate.drawerViewController
                self.navigationController?.presentViewController(vc, animated: true, completion: nil)
//                self.navigationController?.pushViewController(vc, animated: true)

                print("fetched user basic info successfully\n")
            }
        } else {
            let alertController = UIAlertController(title: "Warning",
                                                    message: "Server Issues.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            
            print("unexpected server issues\n")
        }
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        NSLog("%@", error)
        indicator.stopAnimating()
        indicator.alpha = 0
        let alertController = UIAlertController(title: "Warning",
                                                message: "Connection Failure.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        NSLog("connection failed")
        
    }

    //设置Sign In Button的动作
    @IBAction private func signInBtnClicked(sender: UIButton) {
        
        //uncomment/comment the following one line to function normally
        signInPerformed()
        
        //TODO: Test!
        //Uncomment/comment the following three lines to test the main storyboards
//        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        let vc = appDelegate.drawerViewController
//        self.navigationController?.presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction private func resetPassword(sender: UIButton) {
        let sb = UIStoryboard(name: "Initial", bundle: nil);
        let vc = sb.instantiateViewControllerWithIdentifier("ResetPasswordViewController") as UIViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func mNumber() -> String {
        return email!
    }
    
    func mPassword() -> String {
        return password!
    }
    
    // Facebook Delegate Methods
    
    private func facebookVerifyWithUserName(userName: String) {
        let dataString = NSString.localizedStringWithFormat("{\"username\":\"%@\"}",userName)
        let sent = NSData(data: dataString.dataUsingEncoding(NSASCIIStringEncoding)!)
        let dataLength = NSString.localizedStringWithFormat("%ld", sent.length)
        //Bugfix -- Dempsy July.2nd
        let path = usefulConstants().domainAddress + "/checkFacebook"
        let url = NSURL(string: path)
        print("facebook login request: \(path)\n")
        let request = NSMutableURLRequest()
        request.URL = url
        request.HTTPMethod = "POST"
        request.setValue(dataLength as String, forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = sent
        
        let conn = NSURLConnection(request: request, delegate: self, startImmediately: true)
        indicator.alpha = 1
        indicator.startAnimating()
        if (conn == nil) {
            let alertController = UIAlertController(title: "Warning",
                                                    message: "Connection Failure.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In\n")
        
        if ((error) != nil)
        {
            // Process error
            print("error: \(error)\n")
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
                if (FBSDKAccessToken.currentAccessToken() != nil) {
                    let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email"])
                    graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                        
                        if ((error) != nil)
                        {
                            // Process error
                            print("Error: \(error)\n")
                        }
                        else
                        {
                            print("fetched user: \(result)\n")
                            self.firstName = result.valueForKey("first_name") as? String
                            print("First Name is: \(self.firstName)\n")
                            self.lastName = result.valueForKey("last_name") as? String
                            print("Last Name is: \(self.lastName)\n")
                            self.email = result.valueForKey("email") as? String
                            print("Email is: \(self.email)\n")
                            self.facebookVerifyWithUserName(self.email!)
                        }
                    })
                }
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out\n")
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
