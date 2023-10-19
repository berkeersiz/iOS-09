//
//  ViewController.swift
//  10-TravelBook
//
//  Created by Berke Ersiz on 22.08.2023.
//

import UIKit
import MapKit
import CoreLocation//Kullanicinin konumunu almak.
import CoreData


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    //touchcoordinatesten enlem boylami alip coredataya kaydetmek icin tanimladik.
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    //Adde mi yoksa kayitli bir dataya mi basildi kontrol icin.
    var selectedTitle = ""
    var selectedId : UUID?
    
    //Annotation
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()//kullanicinin yerini almaya basladik.
        
        //Recognizer
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer: )))
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        
        if selectedTitle != "" {
            //Core Data
            /*let stringUUID = selectedId!.uuidString
            print(stringUUID)*/
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subTitle = result.value(forKey: "subtitle") as? String {
                                annotationSubTitle = title
                                
                                if let longitude = result.value(forKey: "longitude") as? Double {
                                    annotationLongitude = longitude
                                    
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubTitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubTitle
                                        
                                        
                                        //Kaydettiğimiz yerlere girince guncel yerimizi degil girdigimiz yerin konumu gostersin diye yapiyoruz.
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                    
                                }
                            }
                        
                        }
                        
                    }
                }
            }catch{
                print("error")
            }
            
        }else{
            //Add New Data  
        }
        
    }
    
    
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        //dokunulan koordinatlari almamiz icin.
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let touchCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            chosenLatitude = touchCoordinates.latitude
            chosenLongitude = touchCoordinates.longitude
            
            //dokunulan koordinatlara pin ekleme.
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
        }
        
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {//guncellenen lokasyonlari dizi halinde verir.
        //cllocation objesi enlem ve boylamlardan olusur.
        
        //Locationmanagere if ekleyip eger title bos ise calis dicez yoksa senkronize olarak kotu calisiyor.
        
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }else {
            //
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
         //Bu fonksiyonu yazmazsak kendi anotasyonunu koyuyor ama bu fonksiyon sayesinde pinimizi ozellestirebiliriz.
        
        if annotation is MKUserLocation {//Kullanicimin oldugu anlik yeri pinlemek istemedigimden bunu yaziyorum.
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "reuseId") as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //Pinimizde ozellistirerek koydugumuz i isaretine navigasyon eklemek icin hazir bir fonksiyon.
        
        if selectedTitle != "" {
            let requestLocaiton = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocaiton) { placemarks, error in //Closure
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark:  newPlacemark)
                        item.name = self.annotationTitle//Closureın icinde self zorunlu.
                        let launchOption = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOption)
                        //Bizim navigasyonu acabilmemiz icin bir tane MKMApItem ihtiyacimiz vardi
                        //Launchoption sayesinde hangi modda acacagimiza karar verdik.
                        //Bu mapitemi olusturabilmemiz icin de bir tane MKPlacemark objesine ihtiyacimiz var.
                        //Bu objeyi de reverseGeocodeLocation methoduyla aliyoruz.
                        //Ve navigasyonumuz kurulmus oluyor.
                    }
                }
                
            }
        }
    }


    @IBAction func saveClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        
        //Save islemi bittikten sonra bir mesaj gonder ve tableviewe verimizi kaydet bizi de onceki sayfaya at.
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)//Butun appe bir mesaj yollar diger tarafta da bir observe(gozlemci kullanarak yakalicaz.)
        navigationController?.popViewController(animated: true )
        
        
    }
}

