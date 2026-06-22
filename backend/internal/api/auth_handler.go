package api

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	db        *pgxpool.Pool
	jwtSecret string
}

func NewAuthHandler(db *pgxpool.Pool, jwtSecret string) *AuthHandler {
	return &AuthHandler{db: db, jwtSecret: jwtSecret}
}

type RegisterRequest struct {
	Email        string `json:"email"`
	Password     string `json:"password"`
	DisplayName  string `json:"display_name"`
	FactionColor string `json:"faction_color"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// generateToken membuat JWT token baru untuk user yang berhasil login.
func (h *AuthHandler) generateToken(userID string) (string, error) {
	claims := &JWTClaims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)), // Berlaku 30 hari
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(h.jwtSecret))
}

// Register godoc
// @Summary Register a new agent
// @Description Create a new user account and profile
// @Tags auth
// @Accept  json
// @Produce  json
// @Param request body RegisterRequest true "Registration Info"
// @Success 201 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 409 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/register [post]
func (h *AuthHandler) Register(c echo.Context) error {
	req := new(RegisterRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	// Validasi dasar
	if req.Email == "" || req.Password == "" || req.DisplayName == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "email, password, and display_name are required"})
	}
	if len(req.Password) < 6 {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "password must be at least 6 characters"})
	}

	// Hash the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to hash password"})
	}

	var userID string
	tx, err := h.db.Begin(context.Background())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "could not start transaction"})
	}
	defer tx.Rollback(context.Background())

	// Insert into users
	err = tx.QueryRow(context.Background(),
		"INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id",
		req.Email, string(hashedPassword)).Scan(&userID)
	if err != nil {
		if strings.Contains(err.Error(), "unique constraint") || strings.Contains(err.Error(), "23505") {
			return c.JSON(http.StatusConflict, map[string]string{"error": "This email identifier is already claimed by another agent."})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User creation failed: " + err.Error()})
	}

	// Insert into profiles — cari guild berdasarkan warna faksi
	username := req.Email
	var guildID string
	searchColor := strings.ToUpper(req.FactionColor)
	if searchColor == "#FFFF5F00" {
		searchColor = "#FF5F00"
	}

	err = tx.QueryRow(context.Background(), "SELECT id FROM guilds WHERE emblem_color = $1 LIMIT 1", searchColor).Scan(&guildID)
	if err != nil {
		// Fallback ke guild pertama yang ada
		err = tx.QueryRow(context.Background(), "SELECT id FROM guilds LIMIT 1").Scan(&guildID)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "No guilds available in database"})
		}
	}

	_, err = tx.Exec(context.Background(),
		"INSERT INTO profiles (id, display_name, username, guild_id, territory_color) VALUES ($1, $2, $3, $4, $5)",
		userID, req.DisplayName, username, guildID, req.FactionColor)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Profile creation failed: " + err.Error()})
	}

	if err := tx.Commit(context.Background()); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "could not commit transaction"})
	}

	// Generate JWT token langsung setelah registrasi berhasil
	token, err := h.generateToken(userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to generate token"})
	}

	return c.JSON(http.StatusCreated, map[string]string{
		"id":      userID,
		"token":   token,
		"message": "user registered successfully",
	})
}

// Login godoc
// @Summary Login agent
// @Description Authenticate user and return JWT token
// @Tags auth
// @Accept  json
// @Produce  json
// @Param request body LoginRequest true "Login Credentials"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /auth/login [post]
func (h *AuthHandler) Login(c echo.Context) error {
	req := new(LoginRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	var userID string
	var hashedPassword string
	err := h.db.QueryRow(context.Background(),
		"SELECT id, password_hash FROM users WHERE email = $1",
		req.Email).Scan(&userID, &hashedPassword)

	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "invalid credentials"})
	}

	if err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(req.Password)); err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "invalid credentials"})
	}

	// Generate JWT token
	token, err := h.generateToken(userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to generate token"})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"id":      userID,
		"token":   token,
		"message": "login successful",
	})
}
