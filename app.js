let localStream;
let peerConnection;

const chatBox = document.getElementById('chat-box');
const messageInput = document.getElementById('messageInput');
const sendMessageButton = document.getElementById('sendMessageButton');
const startVoiceButton = document.getElementById('startVoiceButton');
const endVoiceButton = document.getElementById('endVoiceButton');
const shareScreenButton = document.getElementById('shareScreenButton');
const localAudio = document.getElementById('localAudio');
const remoteAudio = document.getElementById('remoteAudio');
const remoteScreen = document.getElementById('remoteScreen');

startVoiceButton.addEventListener('click', startVoiceCall);
endVoiceButton.addEventListener('click', endVoiceCall);
sendMessageButton.addEventListener('click', sendMessage);
shareScreenButton.addEventListener('click', shareScreen);

async function startVoiceCall() {
    try {
        localStream = await navigator.mediaDevices.getUserMedia({ audio: true });

        localAudio.srcObject = localStream;
        localAudio.play();

        startVoiceButton.disabled = true;
        endVoiceButton.disabled = false;
        shareScreenButton.disabled = false;

        const configuration = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] };
        peerConnection = new RTCPeerConnection(configuration);

        localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));

        peerConnection.onicecandidate = handleICECandidateEvent;
        peerConnection.onnegotiationneeded = handleNegotiationNeededEvent;

        const remoteStream = new MediaStream();
        remoteAudio.srcObject = remoteStream;
        remoteAudio.play();

        const remoteScreenStream = new MediaStream();
        remoteScreen.srcObject = remoteScreenStream;
        remoteScreen.play();

        peerConnection.ontrack = handleTrackEvent(remoteStream, remoteScreenStream);

        const offer = await peerConnection.createOffer();
        await peerConnection.setLocalDescription(offer);

        const data = {
            offer: offer,
        };

        // Skicka offer till den andra användaren (implementera en server för detta ändamål)
    } catch (error) {
        handleError(error);
    }
}

function handleNegotiationNeededEvent() {
    peerConnection.createOffer().then(offer => {
        return peerConnection.setLocalDescription(offer);
    }).then(() => {
        // Skicka det lokala beskrivningsobjektet till den andra användaren
    }).catch(handleError);
}

function handleICECandidateEvent(event) {
    if (event.candidate) {
        // Skicka ICE-kandidaten till den andra användaren
    }
}

function handleTrackEvent(remoteStream, remoteScreenStream) {
    return event => {
        if (event.track.kind === 'audio') {
            remoteStream.addTrack(event.track);
        } else if (event.track.kind === 'video') {
            remoteScreenStream.addTrack(event.track);
        }
    };
}

function endVoiceCall() {
    if (peerConnection) {
        peerConnection.close();
    }
    if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
    }

    startVoiceButton.disabled = false;
    endVoiceButton.disabled = true;
    shareScreenButton.disabled = true;
}

function sendMessage() {
    const message = messageInput.value;
    if (message.trim() !== "") {
        const chatMessage = document.createElement('p');
        chatMessage.innerText = `You: ${message}`;
        chatBox.appendChild(chatMessage);

        // Skicka meddelandet till den andra användaren (implementera en server för detta ändamål)

        messageInput.value = "";
    }
}

function shareScreen() {
    navigator.mediaDevices.getDisplayMedia({ video: true })
        .then(screenStream => {
            const senders = peerConnection.getSenders();
            const screenTrack = screenStream.getTracks()[0];

            senders.forEach(sender => {
                if (sender.track.kind === 'video') {
                    sender.replaceTrack(screenTrack);
                }
            });

            screenStream.getTracks().forEach(track => peerConnection.addTrack(track, screenStream));
        })
        .catch(handleError);
}

function handleError(error) {
    console.error('Error: ', error);
}
