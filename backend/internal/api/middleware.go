package api

import (
	"log"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

// JWTClaims adalah struktur isi payload token JWT kita.
type JWTClaims struct {
	UserID string `json:"user_id"`
	jwt.RegisteredClaims
}

// JWTMiddleware memvalidasi token Bearer di header Authorization.
// Jika valid, user_id akan disimpan di context Echo untuk dipakai handler selanjutnya.
func JWTMiddleware(secret string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			authHeader := c.Request().Header.Get("Authorization")
			hasBearerPrefix := strings.HasPrefix(authHeader, "Bearer ")
			log.Printf(
				"JWT_CHECK: method=%s path=%s auth_present=%t bearer_prefix=%t",
				c.Request().Method,
				c.Request().URL.Path,
				authHeader != "",
				hasBearerPrefix,
			)
			if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
				log.Printf("JWT_REJECT: method=%s path=%s reason=missing_or_invalid_header", c.Request().Method, c.Request().URL.Path)
				return c.JSON(http.StatusUnauthorized, map[string]string{"error": "missing or invalid authorization header"})
			}

			tokenStr := strings.TrimPrefix(authHeader, "Bearer ")

			token, err := jwt.ParseWithClaims(tokenStr, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, echo.ErrUnauthorized
				}
				return []byte(secret), nil
			})

			if err != nil || !token.Valid {
				log.Printf("JWT_REJECT: method=%s path=%s reason=invalid_or_expired_token err=%v", c.Request().Method, c.Request().URL.Path, err)
				return c.JSON(http.StatusUnauthorized, map[string]string{"error": "invalid or expired token"})
			}

			claims, ok := token.Claims.(*JWTClaims)
			if !ok {
				log.Printf("JWT_REJECT: method=%s path=%s reason=invalid_claims_type", c.Request().Method, c.Request().URL.Path)
				return c.JSON(http.StatusUnauthorized, map[string]string{"error": "invalid token claims"})
			}

			// Simpan user_id ke context agar bisa dipakai di handler
			c.Set("user_id", claims.UserID)
			log.Printf(
				"JWT_ACCEPT: method=%s path=%s user_id=%s expires_at=%s",
				c.Request().Method,
				c.Request().URL.Path,
				claims.UserID,
				claims.ExpiresAt.Time.UTC().Format("2006-01-02T15:04:05Z"),
			)
			return next(c)
		}
	}
}
