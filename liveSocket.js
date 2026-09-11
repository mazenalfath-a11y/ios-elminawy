// sockets/liveSocket.js
const { Server } = require("socket.io");

const liveMessages = {}; // { courseId: [ { username, message } ] }

function initSocket(server) {
  const io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
  });

  io.on("connection", (socket) => {


    socket.on("createLive", (courseId) => {
        if (!courseId) return;

        if (!liveMessages[courseId]) {
            liveMessages[courseId] = [];
            console.log(`📡 Live created for course: ${courseId}`);
        }

        socket.join(courseId);
    });


    socket.on("joinLive", (courseId) => {
        if (!courseId) return;

        if (!liveMessages[courseId]) {
            socket.emit("liveNotFound", { message: "Live session not found." });
            return;
        }

        socket.join(courseId);
        socket.emit("chatHistory", liveMessages[courseId]);
    });

    socket.on("sendMessage", ({ courseId, username, userNumber, message, audioUrl }) => {
        if (!courseId || !username || (!message && !audioUrl) || !userNumber) return;

        const msg = {
            id: Date.now().toString() + Math.floor(Math.random() * 1000),
            username,
            userNumber,
            message: message || "", // نص الرسالة
            audioUrl: audioUrl || "", // رابط الصوت إن وجد
            timestamp: Date.now(),
        };

        if (!liveMessages[courseId]) liveMessages[courseId] = [];
        if (liveMessages[courseId].length > 100) {
            liveMessages[courseId].shift();
        }

        liveMessages[courseId].push(msg);
        io.to(courseId).emit("receiveMessage", msg);
    });

    socket.on("deleteMessage", ({ courseId, messageId }) => {
        if (!courseId || !messageId) return;

        const msgs = liveMessages[courseId];
        if (!msgs) return;

        liveMessages[courseId] = msgs.filter(msg => msg.id !== messageId);

        io.to(courseId).emit("messageDeleted", messageId);
    });

    socket.on("endLive", (courseId) => {
      if (!courseId) return;
      delete liveMessages[courseId];
      io.to(courseId).emit("liveEnded");
    });

    socket.on("disconnect", () => {
      console.log("🔴 Disconnected:", socket.id);
    });
  });

  return io;
}

function createLiveForCourse(courseId) {
  if (!courseId) return;

  if (!liveMessages[courseId]) {
    liveMessages[courseId] = [];
    console.log(`📡 Live created from API for course: ${courseId}`);
  }
}

module.exports = {
  initSocket,
  createLiveForCourse,
};

