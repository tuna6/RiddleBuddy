document.getElementById("jokeBtn").onclick = async () => {
  const output = document.getElementById("output");
  output.textContent = "Thinking... 🤔";

  try {
    const res = await fetch("/joke");
    const data = await res.json();

    if (data.question && data.answer) {
      output.textContent = `${data.question}\n\n${data.answer}`;
    } else {      output.textContent = "No joke 😅";
    }
  } catch {
    output.textContent = "Oops 😵";
  }
};
