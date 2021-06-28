//
//  ViewController.swift
//  login
//
//  Created by Jorge Luis Baltazar Pérez on 08/06/21.
//

import UIKit



class ViewController: UIViewController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        
        
        //Comprobar sesion del usuario
        let defaults = UserDefaults.standard
        
        if let email = defaults.value(forKey: "email") as?
            String{
            performSegue(withIdentifier: "logueado", sender: self)
        }
    
    }


}

