package main

import (
	"bytes"
	"fmt"
	"image"
	"image/jpeg"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/nfnt/resize"
)

func writeErr(w http.ResponseWriter, err error) {
	w.WriteHeader(http.StatusBadRequest)
	w.Header().Set("Content-Type", "text")
	w.Write([]byte(err.Error()))
}

func uploadFile(w http.ResponseWriter, r *http.Request) error {
	width, err := strconv.Atoi(r.URL.Query().Get("width"))
	if err != nil {
		return fmt.Errorf("Width: %w", err)
	}
	height, err := strconv.Atoi(r.URL.Query().Get("height"))
	if err != nil {
		return fmt.Errorf("Height: %w", err)
	}

	fmt.Printf("Width: %v  Height: %v\n", width, height)

	// Maximum upload of 10 MB files
	err = r.ParseMultipartForm(10 << 20)
	if err != nil {
		return fmt.Errorf("ParseMultipartForm: %w", err)
	}

	for key, _ := range r.MultipartForm.File {
		fmt.Printf("File: %v\n", key)
		// Get handler for filename, size and headers
		file, handler, err := r.FormFile(key)
		if err != nil {
			return fmt.Errorf("Error Retrieving the File: %w", err)
		}

		defer file.Close()
		fmt.Printf("Uploaded File: %+v\n", handler.Filename)
		fmt.Printf("File Size: %+v\n", handler.Size)
		fmt.Printf("MIME Header: %+v\n", handler.Header)

		imageData, imageType, err := image.Decode(file)
		if err != nil {
			return fmt.Errorf("image.Decode: %w", err)
		}
		fmt.Printf("Image Type: %v\n", imageType)

		newImage := resize.Resize(uint(width), uint(height), imageData, resize.Lanczos3)

		imageBytes := new(bytes.Buffer)
		jpeg.Encode(imageBytes, newImage, nil)

		w.WriteHeader(http.StatusOK)
		w.Header().Set("Content-Type", "application/octet-stream")
		w.Write(imageBytes.Bytes())
		return nil
	}

	return fmt.Errorf("No image found")
}


func ReceiveFile(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		//display(w, "upload", nil)
	case "POST":
		err := uploadFile(w, r)
		if err != nil {
			log.Println(err)
			writeErr(w, err)
		}
	}

	return
}

func health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprintf(w, "ok")
}

func main() {
	router := mux.NewRouter()
	router.
		Path("/").
		Methods("GET").
		HandlerFunc(health)
	router.
		Path("/resize").
		Methods("POST").
		HandlerFunc(ReceiveFile)
	log.Println("Starting Resizer . . .")
	log.Fatal(http.ListenAndServe(":8080", router))
}
