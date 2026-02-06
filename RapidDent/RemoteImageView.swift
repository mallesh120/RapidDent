//
//  RemoteImageView.swift
//  RapidDent
//
//  Async image loader for question images
//

import SwiftUI

struct RemoteImageView: View {
    let url: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            } else if isLoading {
                ProgressView()
                    .frame(height: 200)
            } else if loadError {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Failed to load image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageURL = URL(string: url) else {
            loadError = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = uiImage
                } else {
                    loadError = true
                }
            }
        }.resume()
    }
}

#Preview {
    RemoteImageView(url: "https://via.placeholder.com/400x300")
        .padding()
}
