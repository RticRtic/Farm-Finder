//
//  ContentView.swift
//  Farm-Finder
//
//  Created by vatran robert on 2022-01-12.
//

import SwiftUI
import Firebase
import FirebaseStorage
import MapKit

struct ContentView: View {
    var db = Firestore.firestore()
    var auth = Auth.auth()
    @State var farms = [FarmEntry]()
    
    var body: some View {
        List(){
            ForEach(farms)
            { entry in
                NavigationLink(destination: FarmEntryView(entry: entry)) {
                    HStack{
                        
                        AsyncImage(url: URL(string: entry.image)){image in
                            image
                                .resizable()
                                .frame(width: 130, height: 130)
                                .scaledToFit()
                                .clipShape(Circle())
                        }  placeholder: {
                            //ProgressView()
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 130, height: 130)
                                .scaledToFit()
                                .clipShape(Circle())
                        }
                        VStack{
                            Text(entry.name)
                                .font(.headline)
                            
                            Text(entry.content)
                                .lineLimit(1)
                                .padding()
                        }
                    }
                }
            }
            .background(Color.cyan)
            .cornerRadius(10)
        }
        .onAppear(){
            listenToFirestore()
        }
    }
    func listenToFirestore() {
        db.collection("farms").addSnapshotListener { snapshot, err in
            guard let snapshot = snapshot else { return }
            
            if let err = err {
                print("Error to get documents \(err)")
            } else {
                farms.removeAll()
                for document in snapshot.documents {
                    let result = Result {
                        try document.data(as: FarmEntry.self)
                    }
                    switch result {
                    case.success(let item ) :
                        if let item = item {
                            farms.append(item)
                            for i in farms {
                                print(i)
                            }
                        } else {
                            print("Document does not exist")
                        }
                        
                    case.failure(let error) :
                        print("Error decoding item \(error)")
                        
                    }
                }
            }
        }
    }
}

struct EditProfileView : View {
    @EnvironmentObject var viewModel : AppViewModel
    
    var db = Firestore.firestore()
    @State var showActionSheet = false
    @State var showImagePicker = false
    @State var anotherView = false
    @State var secondView = false
    @State var sourceType: UIImagePickerController.SourceType = .camera
    @State var uploadImage : UIImage?
    @State var descriptionText : String = ""
    @State var nameFieldText : String = ""
    @State private var imageURL = URL(string:"")
    @State private var showingSheet = false
    @State var entry: FarmEntry? = nil
    @ObservedObject private var locationManager = LocationManager()
    var body: some View {
    let coordinate = locationManager.location?.coordinate ?? CLLocationCoordinate2D()
    
       
        VStack{
            Button(action: {
                self.showActionSheet = true
                print("ADD PICTURE")
            }
                   , label: {
                if uploadImage != nil {
                    Image(uiImage: uploadImage!)
                        .resizable()
                        //.scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                    
                }else{
                    if let entry = entry {
                        AsyncImage(url: URL(string: entry.image)){image in
                            image
                                .resizable()
                                .frame(width: 200, height: 200)
                                //.scaledToFit()
                                .clipShape(Circle())
                        }  placeholder: {
                            //ProgressView()
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 200, height: 200)
                                .scaledToFit()
                                .clipShape(Circle())
                        }
                    } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200, alignment: .trailing)
                        .clipShape(Circle())
                       
                    }
                }
                
            }).actionSheet(isPresented: $showActionSheet){
                ActionSheet(title: Text("Add a picture to the profile"), message: nil, buttons: [
                    
                    .default(Text("Camera"),action: {
                        self.showImagePicker = true
                        self.sourceType = .camera
                    }),
                    .default(Text("Photo library"), action: {
                        self.showImagePicker = true
                        self.sourceType = .photoLibrary
                    }),
                    .cancel()
                ])
            }
            .sheet(isPresented: $showImagePicker){
                imagePicker(image: self.$uploadImage, showImagePicker:
                                self.$showImagePicker, sourceType:
                                self.sourceType)
            }
            
            Text("Add a picture ")
            if let entry = entry {
                if entry.name == "" {
                    TextEditor(text: $nameFieldText)
                    //TextField(nameFieldText, text: $nameFieldText)
                        .font(.largeTitle)
                } else {
                   
                    TextField("\(entry.name)", text: $nameFieldText)
                        .font(.largeTitle)
                
                }
            }
            
            Button("Save location on map") {
                showingSheet.toggle()
            }
            
            .sheet(isPresented: $showingSheet){
                if let entry = entry {
                    MapView(coordinate: coordinate, entry: entry)
                   
                    Text("\(coordinate.latitude), \(coordinate.longitude)")
                        .foregroundColor(.white)
                        .background(.green)
                        .padding(10)
                    Button(action: {
                        self.entry?.latitude = coordinate.latitude
                        self.entry?.longitude = coordinate.longitude
                        showingSheet = false
                    }, label: {
                        Text("Save Location")
                            .font(.headline)
                            .frame(width: 200, height: 60)
                            .foregroundColor(.white)
                            .background(.red)
                            .cornerRadius(25)
                            
                            
//                        Image(systemName: "plus.app")
//                            .frame(width: 50, height: 50, alignment: .center)
//                            .font(.title)
                    })
                    Button(action: {
                        showingSheet = false
                    }, label: {
                        Image(systemName: "x.circle")
                            .frame(width: 50, height: 50, alignment: .center)
                            .font(.title)
                    })
                }
                
            }
            Text("Write down info about your farm")
                .frame(width: 300, height: 20, alignment: .topLeading)
            ScrollView{
            if let entry = entry {
                if entry.content == "" {
                    TextEditor(text: $descriptionText)
//                    TextField(descriptionText, text: $descriptionText)
                       .font(.body)
                       .frame(width: 400, height: 250, alignment: .topLeading)
                } else {
                    TextField("\(entry.content)", text: $descriptionText)
                        .font(.body)
                        .frame(width: 400, height: 250, alignment: .topLeading)
                        .lineLimit(7)
                }

            }
            }

            Button(action: {
                if let image = self.uploadImage {
                    uploadTheImage(image: image)
                    secondView = true
                    
                }else{
                    print("error in upload")
                    saveToFirestore()
                    secondView = true
                }
                
            }, label: {
                Text("Save")
                    .foregroundColor(Color.white)
                    .frame(width: 200, height:50)
                    .background(Color.blue)
                    .cornerRadius(25)
            })
            Spacer()
           NavigationLink(destination: ContentView() ,isActive: $secondView) {EmptyView()}

        }
        .onAppear(){
            guard let uid = Auth.auth().currentUser?.uid else { return }
            print("THIS IS UID \(uid)")
            self.entry = FarmEntry(owner: uid ,name: "", content: "", image: "", latitude: 0.0, longitude: 0.0)
            db.collection("farms").whereField("owner", isEqualTo: uid).getDocuments() {
                snapshot, err in
                print("DB Collection")
                guard let snapshot = snapshot else{ print("Snapshot")
                    return }
                
                if let err = err {
                    print("Error to get documents \(err)")
                } else {
                    for document in snapshot.documents {
                        let result = Result {
                            try document.data(as: FarmEntry.self)
                        }
                        switch result {
                        case.success(let item ) :
                            if let item = item {
                                print("item")
                                self.entry = item
                            } else {
                                print("Document does not exist")
                                
                            }
                        case.failure(let error) :
                            print("Error decoding item \(error)")
                        }
                        
                    }
    
                }
            }
        }
    }
    func uploadTheImage(image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("user\(uid)")
        
        guard let imageData = image.jpegData(compressionQuality: 1) else { return }
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        storageRef.putData(imageData, metadata: metaData) {
            metaData, error in
            if error == nil , metaData != nil {
                storageRef.downloadURL {url, error in
                    self.imageURL = url
                    saveToFirestore()
                }
            }
            else {
                print("ERROR IN UPLOAD IMAGE FUNC")
                
            }
        }
    }
    func saveToFirestore() {
        print("save 1")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let user = FarmEntry(owner: uid, name: nameFieldText, content: descriptionText, image : imageURL?.absoluteString ?? entry?.image as! String , latitude: entry?.latitude ?? 59.11966, longitude: entry?.longitude ?? 18.11518)
        
        do {
            _ = try db.collection("farms").document(uid).setData(from: user)
            
        } catch {
            print("Error in saving the data")
        }
        
       // db.collection("users").document(uid).updateData([user])
    }
}
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        //ContentView()
//        //EditProfileView()
//    }
//}
