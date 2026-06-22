package api

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
)

var (
	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true // Allow all origins for now
		},
	}
)

// PresenceUpdate is the message format for live GPS presence.
// Sent from client to server, then re-broadcast to all other clients.
type PresenceUpdate struct {
	Type   string  `json:"type"`    // Always "PRESENCE_UPDATE"
	UserID string  `json:"user_id"`
	Lat    float64 `json:"lat"`
	Lng    float64 `json:"lng"`
	Color  string  `json:"color"`   // User's territory color for rendering
}

type client struct {
	conn   *websocket.Conn
	userID string
}

type Hub struct {
	clients    map[*websocket.Conn]*client
	broadcast  chan []byte
	presence   chan presenceMsg // incoming presence from a specific sender
	register   chan *websocket.Conn
	unregister chan *websocket.Conn
	mu         sync.Mutex
}

type presenceMsg struct {
	sender *websocket.Conn
	data   []byte
}

func NewHub() *Hub {
	return &Hub{
		broadcast:  make(chan []byte, 64),
		presence:   make(chan presenceMsg, 256),
		register:   make(chan *websocket.Conn),
		unregister: make(chan *websocket.Conn),
		clients:    make(map[*websocket.Conn]*client),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case conn := <-h.register:
			h.mu.Lock()
			h.clients[conn] = &client{conn: conn}
			h.mu.Unlock()
			log.Println("WS: Client connected")

		case conn := <-h.unregister:
			h.mu.Lock()
			if c, ok := h.clients[conn]; ok {
				delete(h.clients, conn)
				c.conn.Close()
				log.Printf("WS: Client disconnected (user: %s)\n", c.userID)
			}
			h.mu.Unlock()

		case message := <-h.broadcast:
			// Broadcast to ALL connected clients
			h.mu.Lock()
			for conn, c := range h.clients {
				err := conn.WriteMessage(websocket.TextMessage, message)
				if err != nil {
					log.Printf("WS Broadcast Error: %v\n", err)
					conn.Close()
					delete(h.clients, conn)
					_ = c
				}
			}
			h.mu.Unlock()

		case msg := <-h.presence:
			// Broadcast presence update to all clients EXCEPT the sender
			h.mu.Lock()
			for conn := range h.clients {
				if conn == msg.sender {
					continue // Don't echo back to sender
				}
				err := conn.WriteMessage(websocket.TextMessage, msg.data)
				if err != nil {
					log.Printf("WS Presence Error: %v\n", err)
					conn.Close()
					delete(h.clients, conn)
				}
			}
			h.mu.Unlock()
		}
	}
}

// BroadcastMessage sends a message to all connected clients
func (h *Hub) BroadcastMessage(msg []byte) {
	h.broadcast <- msg
}

type WebSocketHandler struct {
	hub *Hub
}

func NewWebSocketHandler(hub *Hub) *WebSocketHandler {
	return &WebSocketHandler{hub: hub}
}

// HandleWS upgrades the HTTP connection to a WebSocket connection.
// Once connected, the client can send PresenceUpdate JSON messages to share their live GPS.
func (wh *WebSocketHandler) HandleWS(c echo.Context) error {
	ws, err := upgrader.Upgrade(c.Response(), c.Request(), nil)
	if err != nil {
		return err
	}

	wh.hub.register <- ws

	// Read loop: listen for incoming presence messages from this client
	go func() {
		defer func() {
			wh.hub.unregister <- ws
		}()
		for {
			_, rawMsg, err := ws.ReadMessage()
			if err != nil {
				break
			}

			// Parse and validate the presence update
			var update PresenceUpdate
			if err := json.Unmarshal(rawMsg, &update); err != nil {
				log.Printf("WS: Invalid message from client: %v", err)
				continue
			}

			if update.Type != "PRESENCE_UPDATE" || update.UserID == "" {
				continue // Ignore unknown or malformed messages
			}

			// Track userId on this connection
			wh.hub.mu.Lock()
			if c, ok := wh.hub.clients[ws]; ok {
				c.userID = update.UserID
			}
			wh.hub.mu.Unlock()

			// Relay presence to all OTHER clients
			wh.hub.presence <- presenceMsg{sender: ws, data: rawMsg}
		}
	}()

	return nil
}

