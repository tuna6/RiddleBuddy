console.log("APP.JS VERSION 2 LOADED");
let currentJokeId = null;

async function getJoke() {
  const category = document.getElementById("category").value;
  const type = document.getElementById("type").value;

  const questionEl = document.getElementById("question");
  const answerEl = document.getElementById("answer");

  // ⏳ loading state
  questionEl.textContent = "Thinking... 🤔";
  answerEl.textContent = "";
  document.getElementById("feedback").style.display = "none";


  try {
    const res = await fetch(`/joke?category=${category}&type=${type}`);
    const data = await res.json();

    currentJokeId = data.id;
    questionEl.textContent = data.question;
    answerEl.textContent = data.answer;
    document.getElementById("feedback").style.display = "flex";

  } catch {
    console.error("ERROR:", err);
    questionEl.textContent = "Oops!";
    answerEl.textContent = "";
  }
}


async function sendFeedback(type) {
  try {
    await fetch("/feedback", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        jokeId: currentJokeId,
        type: type
      })
    });

  const res = await fetch(`/feedback/${currentJokeId}`);
  const data = await res.json();

  document.getElementById("likes").textContent = data.likes;
  document.getElementById("dislikes").textContent = data.dislikes;
  if (!likesEl || !dislikesEl) {
    console.error("Likes/dislikes elements not found");
    return;
  }
    console.log("feedback sent:", type);
  } catch (err) {
    console.error("feedback error", err);
  }
}
