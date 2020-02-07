function toggleCommentMoreInfo(number) {
    var element = document.getElementById("comment-content-more-info-" + number);
    
    if(element.style.display != "block") {
        element.style.display = "block";
    }
    else {
        element.style.display = "none";
    }

    var button = document.getElementById("toggleCommentMoreInfo-" + number);
    if(button.innerText == "v") {
        button.innerText = "^"
    }
    else {
        button.innerText = "v"
    }

}