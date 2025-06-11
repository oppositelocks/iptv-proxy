package utils

import (
	"fmt"
	"log"
	"net/url"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/incmve/iptv-proxy/pkg/config"
)

func WriteResponseToFile(ctx *gin.Context, resp interface{}, contentType string, optionalURL ...string) {
	WriteResponseToFileWithOverwrite(ctx, resp, false, contentType, optionalURL...)
}

func WriteResponseToFileWithOverwrite(ctx *gin.Context, resp interface{}, overwrite bool, contentType string, optionalURL ...string) {
	// Define the cache directory
	cacheDir := config.CacheFolder
	if cacheDir == "" {
		// No where to save the files.
		return
	}

	// Ensure the cache directory exists
	if err := os.MkdirAll(cacheDir, 0755); err != nil {
		log.Printf("Error creating cache directory: %v", err)
		return
	}

	// Determine which URL to use
	var urlString string
	if len(optionalURL) > 0 && optionalURL[0] != "" {
		urlString = optionalURL[0]
	} else {
		urlString = ctx.Request.URL.String()
	}

	// Determine file extension based on response type
	var extension string
	switch contentType {
	case "application/json":
		extension = ".json"
	case "application/xml", "text/xml":
		extension = ".xml"
	case "text/plain":
		extension = ".txt"
	case "application/x-mpegURL", "application/vnd.apple.mpegurl":
		extension = ".m3u8"
	case "audio/x-mpegurl":
		extension = ".m3u"
	default:
		extension = ".json"
	}

	// Generate filename with correct extension
	filename := filepath.Join(cacheDir, url.QueryEscape(urlString) + extension)

	// Convert the response to a string
	respString := ConvertResponseToString(resp)

	// Check if the file exists
	_, err := os.Stat(filename)
	fileExists := !os.IsNotExist(err)

	if !fileExists || (fileExists && overwrite) {
		// Create or overwrite the file
		file, err := os.Create(filename)
		if err != nil {
			log.Printf("Error creating/opening file: %v", err)
			return
		}
		defer file.Close()

		if _, err := file.WriteString(respString); err != nil {
			log.Printf("Error writing to file: %v", err)
		} else {
			if fileExists {
				DebugLog("File overwritten: %s", filename)
			} else {
				DebugLog("Response written to new file: %s", filename)
			}
		}
	}
}

// ConvertResponseToString converts an interface response to a string
func ConvertResponseToString(resp interface{}) string {
	var respString string
	switch v := resp.(type) {
	case string:
		respString = v
	case []byte:
		respString = string(v)
	default:
		respString = fmt.Sprintf("%v", v)
	}

	return respString
}
