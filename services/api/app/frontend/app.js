console.log("APP.JS VERSION 2 LOADED");

async function getJoke() {
  const category = document.getElementById("category").value;
  const type = document.getElementById("type").value;

  const questionEl = document.getElementById("question");
  const answerEl = document.getElementById("answer");

  // ⏳ loading state
  questionEl.textContent = "Thinking... 🤔";
  answerEl.textContent = "";

  try {
    const res = await fetch(`/joke?category=${category}&type=${type}`);
    const data = await res.json();

    questionEl.textContent = data.question;
    answerEl.textContent = data.answer;
    const feedback = document.getElementById("feedback");
    console.log(feedback);
    feedback.style.display = "block";

  } catch {
    console.error("ERROR:", err);
    questionEl.textContent = "Oops!";
    answerEl.textContent = "";
  }
}
