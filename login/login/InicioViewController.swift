//
//  InicioViewController.swift
//  login
//
//  Created by Jorge Luis Baltazar Pérez on 12/06/21.
//

import UIKit
import Firebase
import FirebaseFirestore


class InicioViewController: UIViewController {
    var nombreUsuario: String?
    var chats = [Mensaje]()
    
    //Agregar la referencia a la BD Firestore
    let db = Firestore.firestore()
    
    @IBOutlet weak var mensajeEnviarTF: UITextField!
    @IBOutlet weak var tablaChat: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tablaChat.reloadData()
        
        //registar celda personalizada
        let nib = UINib(nibName: "MensajeTableViewCell", bundle: nil)
        tablaChat.register(nib, forCellReuseIdentifier: "celda")
        
        //ocultar el boton de regresar
        navigationItem.hidesBackButton = true
        cargarMensajes()
        
        if let email = Auth.auth().currentUser?.email{
            let defaults = UserDefaults.standard
            
            defaults.setValue(email, forKey: "email")
            defaults.synchronize()
        }
    }
    
    
    
    func cargarMensajes(){
        db.collection("mensajes")
            .order(by: "fechaCreacion")
            .addSnapshotListener() { (querySnapshot, err) in
                //Vaciar arreglo de chats
                self.chats = []
                
            if let e = err {
                print("Error al obtener los chats: \(e.localizedDescription)")
            } else {
                if let snapshotDocumentos = querySnapshot?.documents {
                    for document in snapshotDocumentos {
                        //crear mi objeto mensaje
                        let datos = document.data()
                        print(datos)
                        // Sacar los parametros p obj Mensaje
                        guard let remitenteFS = datos["remitente"] as? String else { return }
                        guard let mensajeFS = datos["mensaje"] as? String else { return }
                        
                        let nuevoMensaje = Mensaje(remitente: remitenteFS, cuerpoMsj: mensajeFS)
                        
                        self.chats.append(nuevoMensaje)
                        
                        DispatchQueue.main.async {
                            self.tablaChat.reloadData()
                        }
                       
                     }
                }
                
            }
        }
        
        
    }
    
    @IBAction func enviarButton(_ sender: UIButton) {
        if let mensaje = mensajeEnviarTF.text, let remitente = Auth.auth().currentUser?.email {
            db.collection("mensajes").addDocument(data: [
                "remitente": remitente,
                "mensaje": mensaje,
                "fechaCreacion": Date().timeIntervalSince1970
            ]) { (error) in
                //si hubo errro
                if let e = error {
                    print("Error al guardar en Firestore \(e.localizedDescription)")
                } else {
                    //Se realizo la insersion a firestore
                    print("Se guardo la info en firestore")
                    self.mensajeEnviarTF.text = ""
                }
            }
        }
    }
    @IBAction func salirButton(_ sender: UIBarButtonItem) {
        
        //cerrar sesion
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "email")
        defaults.synchronize()
        
        let firebaseAuth = Auth.auth()
        print("Cerro sesion correctamente")
        navigationController?.popToRootViewController(animated: true)
    do {
      try firebaseAuth.signOut()
    } catch let error as NSError {
        print ("Error al cerrar sesiont: \(error.localizedDescription)")
    }
      
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "perfil" {
                let destino = segue.destination as! PerfilViewController
                destino.nombreUsuario = Auth.auth().currentUser?.email
            }
        }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension InicioViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tablaChat.dequeueReusableCell(withIdentifier: "celda", for: indexPath) as! MensajeTableViewCell
        celda.mensajeLabel?.text = chats[indexPath.row].cuerpoMsj
        
        let perfil = self.db.collection("perfiles").document(chats[indexPath.row].remitente)
                perfil.getDocument{ (document, error) in
                    if let document = document, document.exists {
                        celda.destinatarioLabel?.text = "\(document.data()!["nombre"]!)"
                        let urlString = document.data()!["imagen"] as? String
                        let url = URL(string: urlString!)

                        DispatchQueue.main.async { [weak self] in
                            if let data = try? Data(contentsOf: url!) {
                                if let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        celda.imagenPerfil.image = image
                                    }
                                }
                            }
                        }
                        } else {
                            print("Document does not exist")
                        }
                }
        
        return celda
    }
    
    
}
