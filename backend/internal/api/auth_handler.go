package api

import (
	"context"
	"log"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	db *pgxpool.Pool
}

func NewAuthHandler(db *pgxpool.Pool) *AuthHandler {
	return &AuthHandler{db: db}
}

type RegisterRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
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
		log.Printf("Registration DB Error: %v", err)
		// Robust check for duplicate key error
		if strings.Contains(err.Error(), "unique constraint") || strings.Contains(err.Error(), "23505") {
			return c.JSON(http.StatusConflict, map[string]string{"error": "This email identifier is already claimed by another agent."})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User creation failed: " + err.Error()})
	}

	// Insert into profiles
	username := req.Email // Simple fallback
	_, err = tx.Exec(context.Background(),
		"INSERT INTO profiles (id, display_name, username) VALUES ($1, $2, $3)",
		userID, req.DisplayName, username)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Profile creation failed: " + err.Error()})
	}

	if err := tx.Commit(context.Background()); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "could not commit transaction"})
	}

	return c.JSON(http.StatusCreated, map[string]string{
		"id":      userID,
		"message": "user registered successfully",
	})
}

// Login godoc
// @Summary Login agent
// @Description Authenticate user and get session ID
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

	// Compare hashed password
	if err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(req.Password)); err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "invalid credentials"})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"id":      userID,
		"message": "login successful",
	})
}
