package api

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type FriendsHandler struct {
	db *pgxpool.Pool
}

func NewFriendsHandler(db *pgxpool.Pool) *FriendsHandler {
	return &FriendsHandler{db: db}
}

// SendFriendRequest — POST /friends/request
// Mengirimkan permintaan pertemanan ke user lain.
func (h *FriendsHandler) SendFriendRequest(c echo.Context) error {
	senderID := c.Get("user_id").(string)

	var req struct {
		FriendID string `json:"friend_id"`
	}
	if err := c.Bind(&req); err != nil || req.FriendID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "friend_id is required"})
	}

	if senderID == req.FriendID {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "cannot send friend request to yourself"})
	}

	ctx := context.Background()

	// Cek apakah sudah ada relasi
	var existing string
	err := h.db.QueryRow(ctx,
		"SELECT status FROM friendships WHERE (user_id=$1 AND friend_id=$2) OR (user_id=$2 AND friend_id=$1)",
		senderID, req.FriendID).Scan(&existing)
	if err == nil {
		return c.JSON(http.StatusConflict, map[string]string{"error": "friendship request already exists", "status": existing})
	}

	// Insert permintaan baru
	_, err = h.db.Exec(ctx,
		"INSERT INTO friendships (user_id, friend_id, status) VALUES ($1, $2, 'pending')",
		senderID, req.FriendID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to send friend request"})
	}

	return c.JSON(http.StatusCreated, map[string]string{"message": "friend request sent"})
}

// AcceptFriendRequest — PUT /friends/:friendId/accept
// Menerima permintaan pertemanan yang masuk.
func (h *FriendsHandler) AcceptFriendRequest(c echo.Context) error {
	userID := c.Get("user_id").(string)
	friendID := c.Param("friendId")

	ctx := context.Background()
	tag, err := h.db.Exec(ctx,
		"UPDATE friendships SET status='accepted' WHERE user_id=$1 AND friend_id=$2 AND status='pending'",
		friendID, userID) // friendID adalah yang mengirim, userID adalah yang menerima
	if err != nil || tag.RowsAffected() == 0 {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "pending friend request not found"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "friend request accepted"})
}

// RemoveFriend — DELETE /friends/:friendId
// Menghapus pertemanan atau memblokir user.
func (h *FriendsHandler) RemoveFriend(c echo.Context) error {
	userID := c.Get("user_id").(string)
	friendID := c.Param("friendId")

	ctx := context.Background()
	_, err := h.db.Exec(ctx,
		"DELETE FROM friendships WHERE (user_id=$1 AND friend_id=$2) OR (user_id=$2 AND friend_id=$1)",
		userID, friendID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to remove friend"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "friend removed"})
}

// GetFriends — GET /friends
// Mengembalikan daftar teman yang sudah diterima.
func (h *FriendsHandler) GetFriends(c echo.Context) error {
	userID := c.Get("user_id").(string)
	ctx := context.Background()

	rows, err := h.db.Query(ctx, `
		SELECT p.id, p.display_name, p.username, p.avatar_url, p.territory_color, p.level
		FROM friendships f
		JOIN profiles p ON (
			CASE WHEN f.user_id = $1 THEN f.friend_id ELSE f.user_id END = p.id
		)
		WHERE (f.user_id = $1 OR f.friend_id = $1) AND f.status = 'accepted'
	`, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch friends"})
	}
	defer rows.Close()

	type FriendInfo struct {
		ID             string  `json:"id"`
		DisplayName    *string `json:"display_name"`
		Username       *string `json:"username"`
		AvatarURL      *string `json:"avatar_url"`
		TerritoryColor *string `json:"territory_color"`
		Level          int     `json:"level"`
	}

	friends := []FriendInfo{}
	for rows.Next() {
		var f FriendInfo
		if err := rows.Scan(&f.ID, &f.DisplayName, &f.Username, &f.AvatarURL, &f.TerritoryColor, &f.Level); err != nil {
			continue
		}
		friends = append(friends, f)
	}

	return c.JSON(http.StatusOK, friends)
}

// GetPendingRequests — GET /friends/pending
// Mengembalikan daftar permintaan pertemanan yang menunggu konfirmasi.
func (h *FriendsHandler) GetPendingRequests(c echo.Context) error {
	userID := c.Get("user_id").(string)
	ctx := context.Background()

	rows, err := h.db.Query(ctx, `
		SELECT p.id, p.display_name, p.username, p.avatar_url, p.territory_color, f.created_at
		FROM friendships f
		JOIN profiles p ON f.user_id = p.id
		WHERE f.friend_id = $1 AND f.status = 'pending'
		ORDER BY f.created_at DESC
	`, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch pending requests"})
	}
	defer rows.Close()

	type PendingRequest struct {
		ID             string  `json:"id"`
		DisplayName    *string `json:"display_name"`
		Username       *string `json:"username"`
		AvatarURL      *string `json:"avatar_url"`
		TerritoryColor *string `json:"territory_color"`
		RequestedAt    string  `json:"requested_at"`
	}

	requests := []PendingRequest{}
	for rows.Next() {
		var r PendingRequest
		if err := rows.Scan(&r.ID, &r.DisplayName, &r.Username, &r.AvatarURL, &r.TerritoryColor, &r.RequestedAt); err != nil {
			continue
		}
		requests = append(requests, r)
	}

	return c.JSON(http.StatusOK, requests)
}
