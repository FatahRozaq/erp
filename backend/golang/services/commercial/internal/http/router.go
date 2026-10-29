package transport

import (
	"github.com/labstack/echo/v5"
	"net/http"
)

// NewRouter exposes only process health until authenticated domain routes exist.
func NewRouter() http.Handler {
	e := echo.New()
	e.GET("/health/live", func(c *echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok", "service": "commercial"})
	})
	return e
}
