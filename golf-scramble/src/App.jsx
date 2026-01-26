import { useState, useEffect, useRef } from 'react';
import { Plus, Trophy, Camera, Video, RefreshCw, MessageCircle, Send, Users } from 'lucide-react';

export default function GolfScramble() {
  const [teams, setTeams] = useState([]);
  const [myTeamName, setMyTeamName] = useState('');
  const [newTeamName, setNewTeamName] = useState('');
  const [scores, setScores] = useState({});
  const [media, setMedia] = useState({});
  const [currentHole, setCurrentHole] = useState(1);
  const [view, setView] = useState('setup');
  const [newPhotoUrl, setNewPhotoUrl] = useState('');
  const [newVideoUrl, setNewVideoUrl] = useState('');
  const [coursePars, setCoursePars] = useState(Array(18).fill(4));
  const [showParSetup, setShowParSetup] = useState(false);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [showChat, setShowChat] = useState(true);
  const [lastRefresh, setLastRefresh] = useState(new Date());
  const [uploadingMedia, setUploadingMedia] = useState(false);
  const chatEndRef = useRef(null);
  const photoInputRef = useRef(null);
  const videoInputRef = useRef(null);

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const loadData = async () => {
    try {
      const [teamsRes, scoresRes, mediaRes, parsRes, messagesRes] = await Promise.all([
        window.storage.get('golf-teams-v3', true).catch(() => null),
        window.storage.get('golf-scores-v3', true).catch(() => null),
        window.storage.get('golf-media-v3', true).catch(() => null),
        window.storage.get('golf-pars-v3', true).catch(() => null),
        window.storage.get('golf-messages-v3', true).catch(() => null)
      ]);

      if (teamsRes?.value) setTeams(JSON.parse(teamsRes.value));
      if (scoresRes?.value) setScores(JSON.parse(scoresRes.value));
      if (mediaRes?.value) setMedia(JSON.parse(mediaRes.value));
      if (parsRes?.value) setCoursePars(JSON.parse(parsRes.value));
      if (messagesRes?.value) setMessages(JSON.parse(messagesRes.value));

      setLastRefresh(new Date());
    } catch (error) {
      console.log('Loading data:', error);
    }
  };

  const addTeam = async () => {
    if (newTeamName.trim() && !teams.includes(newTeamName.trim())) {
      const updated = [...teams, newTeamName.trim()];
      setTeams(updated);
      await window.storage.set('golf-teams-v3', JSON.stringify(updated), true);
      setNewTeamName('');
    }
  };

  const selectMyTeam = (team) => {
    setMyTeamName(team);
    setView('scorecard');
  };

  const updateScore = async (team, hole, value) => {
    if (team !== myTeamName) {
      alert('You can only update your own team scores!');
      return;
    }
    const score = parseInt(value) || 0;
    const updated = { ...scores, [`${team}-${hole}`]: score };
    setScores(updated);
    await window.storage.set('golf-scores-v3', JSON.stringify(updated), true);
  };

  const addMedia = async (type) => {
    const url = type === 'photo' ? newPhotoUrl : newVideoUrl;
    if (!url.trim()) return;

    const key = `${myTeamName}-${currentHole}-${type}`;
    const updated = {
      ...media,
      [key]: [...(media[key] || []), { url: url.trim(), timestamp: new Date().toISOString() }]
    };
    setMedia(updated);
    await window.storage.set('golf-media-v3', JSON.stringify(updated), true);

    if (type === 'photo') setNewPhotoUrl('');
    else setNewVideoUrl('');
  };

  const handleFileUpload = async (event, type) => {
    const file = event.target.files[0];
    if (!file) return;

    // Validate file
    if (type === 'photo' && !file.type.startsWith('image/')) {
      alert('Please select an image file');
      return;
    }
    if (type === 'video' && !file.type.startsWith('video/')) {
      alert('Please select a video file');
      return;
    }
    if (type === 'video' && file.size > 50 * 1024 * 1024) {
      alert('Video must be under 50MB');
      return;
    }

    setUploadingMedia(true);

    try {
      // Convert to base64
      const reader = new FileReader();
      reader.onload = async (e) => {
        const base64Data = e.target.result;

        const key = `${myTeamName}-${currentHole}-${type}`;
        const mediaItem = {
          data: base64Data,
          timestamp: new Date().toISOString(),
          type: file.type
        };

        const updated = {
          ...media,
          [key]: [...(media[key] || []), mediaItem]
        };

        setMedia(updated);
        await window.storage.set('golf-media-v3', JSON.stringify(updated), true);
        setUploadingMedia(false);
        alert(`${type === 'photo' ? 'Photo' : 'Video'} uploaded!`);
      };

      reader.onerror = () => {
        setUploadingMedia(false);
        alert('Error uploading file');
      };

      reader.readAsDataURL(file);
    } catch (error) {
      setUploadingMedia(false);
      alert('Error: ' + error.message);
    }
  };

  const triggerPhotoUpload = () => {
    photoInputRef.current?.click();
  };

  const triggerVideoUpload = () => {
    videoInputRef.current?.click();
  };

  const sendMessage = async () => {
    if (!newMessage.trim()) return;

    const msg = {
      team: myTeamName,
      text: newMessage.trim(),
      timestamp: new Date().toISOString(),
      id: Date.now()
    };

    const updated = [...messages, msg];
    setMessages(updated);
    setNewMessage('');
    await window.storage.set('golf-messages-v3', JSON.stringify(updated), true);
  };

  const getTeamTotal = (team) => {
    let total = 0;
    for (let i = 1; i <= 18; i++) {
      total += scores[`${team}-${i}`] || 0;
    }
    return total;
  };

  const getTeamToPar = (team) => {
    const total = getTeamTotal(team);
    if (total === 0) return 0;
    const totalPar = coursePars.reduce((sum, par) => sum + par, 0);
    return total - totalPar;
  };

  const getHoleToPar = (team, hole) => {
    const score = scores[`${team}-${hole}`];
    if (!score) return null;
    return score - coursePars[hole - 1];
  };

  const formatToPar = (toPar) => {
    if (toPar === 0) return 'E';
    if (toPar > 0) return `+${toPar}`;
    return toPar.toString();
  };

  const updatePar = async (hole, value) => {
    const par = Math.max(3, Math.min(6, parseInt(value) || 3));
    const updated = [...coursePars];
    updated[hole - 1] = par;
    setCoursePars(updated);
    await window.storage.set('golf-pars-v3', JSON.stringify(updated), true);
  };

  const setStandardPars = async (type) => {
    let pars;
    if (type === 'par72') {
      pars = [4,4,4,5,3,4,4,3,5,4,5,4,3,4,4,5,3,4];
    } else if (type === 'par70') {
      pars = [4,4,3,4,5,4,4,3,4,4,4,5,3,4,4,4,3,5];
    } else {
      pars = Array(18).fill(4);
    }
    setCoursePars(pars);
    await window.storage.set('golf-pars-v3', JSON.stringify(pars), true);
  };

  const resetAll = async () => {
    if (confirm('ADMIN: Reset entire scramble? This deletes EVERYTHING!')) {
      await Promise.all([
        window.storage.set('golf-teams-v3', JSON.stringify([]), true),
        window.storage.set('golf-scores-v3', JSON.stringify({}), true),
        window.storage.set('golf-media-v3', JSON.stringify({}), true),
        window.storage.set('golf-pars-v3', JSON.stringify(Array(18).fill(4)), true),
        window.storage.set('golf-messages-v3', JSON.stringify([]), true)
      ]);
      setTeams([]);
      setScores({});
      setMedia({});
      setMessages([]);
      setCoursePars(Array(18).fill(4));
      setMyTeamName('');
      setView('setup');
    }
  };

  const getLeaderboard = () => {
    return teams
      .map(team => ({
        name: team,
        total: getTeamTotal(team),
        toPar: getTeamToPar(team)
      }))
      .filter(team => team.total > 0)
      .sort((a, b) => a.total - b.total);
  };

  if (view === 'setup') {
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 via-emerald-50 to-green-100 p-4">
        <div className="max-w-3xl mx-auto">
          <div className="bg-white rounded-2xl shadow-2xl p-8">
            <div className="text-center mb-8">
              <div className="flex items-center justify-center gap-3 mb-2">
                <Trophy className="text-yellow-500" size={48} />
                <h1 className="text-4xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                  Golf Scramble
                </h1>
              </div>
              <p className="text-gray-600">Live scoring • Smack talk • Photo sharing</p>
            </div>

            <div className="mb-8">
              <h2 className="text-2xl font-bold mb-4 flex items-center gap-2">
                <Users className="text-green-600" />
                Add Teams
              </h2>
              <div className="flex gap-3">
                <input
                  type="text"
                  value={newTeamName}
                  onChange={(e) => setNewTeamName(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && addTeam()}
                  placeholder="Team name (e.g., Eagle Squad)"
                  className="flex-1 px-4 py-3 border-2 border-gray-300 rounded-xl focus:ring-4 focus:ring-green-200 focus:border-green-500 text-lg"
                />
                <button
                  onClick={addTeam}
                  className="bg-gradient-to-r from-green-600 to-emerald-600 text-white px-8 py-3 rounded-xl hover:from-green-700 hover:to-emerald-700 flex items-center gap-2 font-semibold shadow-lg"
                >
                  <Plus size={24} />
                  Add
                </button>
              </div>
            </div>

            {teams.length > 0 && (
              <div className="mb-8">
                <h2 className="text-2xl font-bold mb-4">Select Your Team</h2>
                <div className="grid gap-3">
                  {teams.map(team => (
                    <button
                      key={team}
                      onClick={() => selectMyTeam(team)}
                      className="bg-gradient-to-r from-green-100 to-emerald-100 hover:from-green-200 hover:to-emerald-200 px-6 py-4 rounded-xl text-left font-bold text-green-900 transition-all transform hover:scale-105 shadow-md"
                    >
                      {team}
                    </button>
                  ))}
                </div>
              </div>
            )}

            <div className="mb-8 pb-8 border-t pt-8">
              <h2 className="text-2xl font-bold mb-4">Course Par Setup</h2>
              <div className="grid grid-cols-3 gap-3 mb-4">
                <button
                  onClick={() => setStandardPars('par72')}
                  className="bg-blue-600 text-white px-4 py-3 rounded-xl hover:bg-blue-700 font-semibold"
                >
                  Par 72
                </button>
                <button
                  onClick={() => setStandardPars('par70')}
                  className="bg-blue-600 text-white px-4 py-3 rounded-xl hover:bg-blue-700 font-semibold"
                >
                  Par 70
                </button>
                <button
                  onClick={() => setShowParSetup(!showParSetup)}
                  className="bg-gray-600 text-white px-4 py-3 rounded-xl hover:bg-gray-700 font-semibold"
                >
                  Custom
                </button>
              </div>

              {showParSetup && (
                <div className="bg-gray-50 rounded-xl p-4">
                  <p className="text-sm text-gray-600 mb-3">Set par for each hole (3-6):</p>
                  <div className="grid grid-cols-6 gap-2">
                    {coursePars.map((par, idx) => (
                      <div key={idx} className="text-center">
                        <label className="text-xs text-gray-600 block mb-1">#{idx + 1}</label>
                        <input
                          type="number"
                          min="3"
                          max="6"
                          value={par}
                          onChange={(e) => updatePar(idx + 1, e.target.value)}
                          className="w-full px-2 py-2 border-2 border-gray-300 rounded-lg text-center font-bold"
                        />
                      </div>
                    ))}
                  </div>
                  <p className="text-sm text-gray-600 mt-3 text-center">
                    Total Par: <span className="font-bold text-lg">{coursePars.reduce((a, b) => a + b, 0)}</span>
                  </p>
                </div>
              )}
            </div>

            <button
              onClick={resetAll}
              className="w-full bg-red-600 text-white px-6 py-3 rounded-xl hover:bg-red-700 font-semibold"
            >
              Admin: Reset Everything
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-emerald-50 to-green-100 p-4">
      <div className="max-w-7xl mx-auto">
        <div className="bg-white rounded-2xl shadow-2xl p-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between mb-6 gap-4">
            <div>
              <div className="flex items-center gap-3">
                <Trophy className="text-yellow-500" size={36} />
                <h1 className="text-3xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                  Live Scramble
                </h1>
              </div>
              <p className="text-green-700 font-bold mt-1">{myTeamName}</p>
              <p className="text-xs text-gray-500">Last refresh: {lastRefresh.toLocaleTimeString()}</p>
            </div>
            <div className="flex gap-2">
              <button
                onClick={loadData}
                className="bg-blue-600 text-white px-4 py-2 rounded-xl hover:bg-blue-700 flex items-center gap-2 font-semibold shadow-lg"
              >
                <RefreshCw size={20} />
                Refresh
              </button>
              <button
                onClick={() => setView('setup')}
                className="bg-gray-600 text-white px-4 py-2 rounded-xl hover:bg-gray-700 font-semibold"
              >
                Settings
              </button>
            </div>
          </div>

          <div className="grid lg:grid-cols-3 gap-6 mb-6">
            {/* Scoring Column */}
            <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl p-5 shadow-lg">
              <h3 className="text-2xl font-bold text-gray-800 mb-4">
                Hole {currentHole} <span className="text-green-600">• Par {coursePars[currentHole - 1]}</span>
              </h3>
              <div className="mb-6">
                <label className="block text-sm font-semibold mb-2">Your Score:</label>
                <input
                  type="number"
                  min="0"
                  max="20"
                  value={scores[`${myTeamName}-${currentHole}`] || ''}
                  onChange={(e) => updateScore(myTeamName, currentHole, e.target.value)}
                  className="w-full px-4 py-4 border-4 border-green-300 rounded-xl text-center text-4xl font-bold focus:ring-4 focus:ring-green-400"
                  placeholder="0"
                />
              </div>

              {getTeamTotal(myTeamName) > 0 && (
                <div className="bg-white rounded-xl p-4 mb-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Total Score:</span>
                    <span className="font-bold text-2xl">{getTeamTotal(myTeamName)}</span>
                  </div>
                  <div className="flex justify-between items-center mt-2">
                    <span className="text-gray-600">To Par:</span>
                    <span className={`font-bold text-2xl ${
                      getTeamToPar(myTeamName) < 0 ? 'text-green-600' :
                      getTeamToPar(myTeamName) > 0 ? 'text-red-600' : 'text-gray-800'
                    }`}>
                      {formatToPar(getTeamToPar(myTeamName))}
                    </span>
                  </div>
                </div>
              )}

              <div className="space-y-3 mb-4">
                <div>
                  <label className="block text-sm font-semibold mb-2">Add Photo:</label>
                  <input
                    ref={photoInputRef}
                    type="file"
                    accept="image/*"
                    capture="environment"
                    onChange={(e) => handleFileUpload(e, 'photo')}
                    className="hidden"
                  />
                  <button
                    onClick={triggerPhotoUpload}
                    disabled={uploadingMedia}
                    className="w-full bg-gradient-to-r from-blue-500 to-blue-600 text-white px-4 py-3 rounded-lg hover:from-blue-600 hover:to-blue-700 flex items-center justify-center gap-2 font-semibold disabled:opacity-50"
                  >
                    <Camera size={20} />
                    {uploadingMedia ? 'Uploading...' : 'Take/Upload Photo'}
                  </button>
                </div>

                <div>
                  <label className="block text-sm font-semibold mb-2">Add Video (30 sec max):</label>
                  <input
                    ref={videoInputRef}
                    type="file"
                    accept="video/*"
                    capture="environment"
                    onChange={(e) => handleFileUpload(e, 'video')}
                    className="hidden"
                  />
                  <button
                    onClick={triggerVideoUpload}
                    disabled={uploadingMedia}
                    className="w-full bg-gradient-to-r from-purple-500 to-purple-600 text-white px-4 py-3 rounded-lg hover:from-purple-600 hover:to-purple-700 flex items-center justify-center gap-2 font-semibold disabled:opacity-50"
                  >
                    <Video size={20} />
                    {uploadingMedia ? 'Uploading...' : 'Record/Upload Video'}
                  </button>
                </div>

                <div className="pt-2 border-t">
                  <label className="block text-xs text-gray-500 mb-1">Or paste a URL:</label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newPhotoUrl}
                      onChange={(e) => setNewPhotoUrl(e.target.value)}
                      placeholder="Photo/Video URL..."
                      className="flex-1 px-3 py-2 border-2 border-gray-300 rounded-lg text-sm"
                    />
                    <button
                      onClick={() => addMedia('photo')}
                      className="bg-gray-600 text-white px-3 py-2 rounded-lg hover:bg-gray-700 text-sm"
                    >
                      Add
                    </button>
                  </div>
                </div>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => setCurrentHole(Math.max(1, currentHole - 1))}
                  disabled={currentHole === 1}
                  className="px-4 py-3 bg-gray-300 rounded-xl hover:bg-gray-400 disabled:opacity-50 font-semibold"
                >
                  Prev
                </button>
                <button
                  onClick={() => setCurrentHole(Math.min(18, currentHole + 1))}
                  disabled={currentHole === 18}
                  className="flex-1 px-4 py-3 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-xl hover:from-green-700 hover:to-emerald-700 font-semibold shadow-lg"
                >
                  Next Hole
                </button>
              </div>
            </div>

            {/* Leaderboard Column */}
            <div className="bg-gradient-to-br from-yellow-50 to-amber-50 rounded-xl p-5 shadow-lg">
              <h3 className="text-2xl font-bold text-gray-800 mb-4 flex items-center gap-2">
                <Trophy className="text-yellow-600" />
                Leaderboard
              </h3>
              {getLeaderboard().length === 0 ? (
                <p className="text-gray-600 text-center py-8">No scores yet!</p>
              ) : (
                <div className="space-y-2">
                  {getLeaderboard().map((team, idx) => (
                    <div
                      key={team.name}
                      className={`flex justify-between items-center p-4 rounded-xl ${
                        idx === 0 ? 'bg-gradient-to-r from-yellow-200 to-amber-200 border-4 border-yellow-400' : 'bg-white'
                      } ${team.name === myTeamName ? 'ring-4 ring-green-500' : ''}`}
                    >
                      <div className="flex items-center gap-3">
                        <span className="font-bold text-xl text-gray-500">#{idx + 1}</span>
                        {idx === 0 && <Trophy className="text-yellow-600" size={24} />}
                        <span className="font-bold text-lg">{team.name}</span>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className={`text-xl font-bold ${
                          team.toPar < 0 ? 'text-green-600' :
                          team.toPar > 0 ? 'text-red-600' : 'text-gray-800'
                        }`}>
                          {formatToPar(team.toPar)}
                        </span>
                        <span className="text-3xl font-bold text-green-700">{team.total}</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Chat Column */}
            <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl p-5 shadow-lg">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
                  <MessageCircle className="text-blue-600" />
                  Smack Talk
                </h3>
                <button
                  onClick={() => setShowChat(!showChat)}
                  className="text-sm text-blue-600 hover:text-blue-800 font-semibold"
                >
                  {showChat ? 'Hide' : 'Show'}
                </button>
              </div>

              {showChat && (
                <>
                  <div className="bg-white rounded-xl p-3 mb-3 h-80 overflow-y-auto shadow-inner">
                    {messages.length === 0 ? (
                      <p className="text-gray-400 text-center mt-16">
                        No messages yet.<br />Start the trash talk!
                      </p>
                    ) : (
                      <div className="space-y-3">
                        {messages.map((msg) => (
                          <div
                            key={msg.id}
                            className={`p-3 rounded-xl ${
                              msg.team === myTeamName
                                ? 'bg-green-100 ml-6 border-l-4 border-green-500'
                                : 'bg-gray-100 mr-6 border-l-4 border-blue-500'
                            }`}
                          >
                            <div className="flex items-center gap-2 mb-1">
                              <span className="font-bold text-sm text-blue-700">
                                {msg.team}
                              </span>
                              <span className="text-xs text-gray-500">
                                {new Date(msg.timestamp).toLocaleTimeString([], {
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })}
                              </span>
                            </div>
                            <p className="text-sm font-medium">{msg.text}</p>
                          </div>
                        ))}
                        <div ref={chatEndRef} />
                      </div>
                    )}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                      onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
                      placeholder="Type your message..."
                      className="flex-1 px-4 py-3 border-2 border-gray-300 rounded-xl text-sm focus:ring-4 focus:ring-blue-200 focus:border-blue-500"
                    />
                    <button
                      onClick={sendMessage}
                      className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-5 py-3 rounded-xl hover:from-blue-700 hover:to-purple-700 flex items-center gap-2 shadow-lg"
                    >
                      <Send size={20} />
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>

          {/* Full Scorecard */}
          <div className="bg-white rounded-xl p-5 shadow-lg mb-6">
            <h3 className="text-2xl font-bold mb-4">Full Scorecard</h3>
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-sm">
                <thead>
                  <tr className="bg-gradient-to-r from-green-600 to-emerald-600 text-white">
                    <th className="p-3 text-left sticky left-0 bg-green-600 rounded-tl-lg">Team</th>
                    {Array.from({ length: 18 }, (_, i) => (
                      <th key={i} className="p-2 text-center">
                        <div className="font-bold">{i + 1}</div>
                        <div className="text-xs font-normal">Par {coursePars[i]}</div>
                      </th>
                    ))}
                    <th className="p-3 text-center font-bold">Total</th>
                    <th className="p-3 text-center font-bold rounded-tr-lg">To Par</th>
                  </tr>
                </thead>
                <tbody>
                  {teams.map((team, idx) => (
                    <tr key={team} className={idx % 2 === 0 ? 'bg-gray-50' : 'bg-white'}>
                      <td className={`p-3 font-bold sticky left-0 ${idx % 2 === 0 ? 'bg-gray-50' : 'bg-white'} ${team === myTeamName ? 'text-green-700' : ''}`}>
                        {team}
                      </td>
                      {Array.from({ length: 18 }, (_, i) => {
                        const score = scores[`${team}-${i + 1}`];
                        const toPar = getHoleToPar(team, i + 1);
                        return (
                          <td key={i} className={`p-2 text-center font-bold ${
                            toPar === null ? '' :
                            toPar < 0 ? 'bg-green-200 text-green-900' :
                            toPar === 0 ? 'bg-gray-200' :
                            toPar === 1 ? 'bg-yellow-200 text-yellow-900' :
                            'bg-red-200 text-red-900'
                          }`}>
                            {score || '-'}
                          </td>
                        );
                      })}
                      <td className="p-3 text-center font-bold text-xl text-green-700">
                        {getTeamTotal(team) || '-'}
                      </td>
                      <td className={`p-3 text-center font-bold text-xl ${
                        getTeamToPar(team) < 0 ? 'text-green-600' :
                        getTeamToPar(team) > 0 ? 'text-red-600' : 'text-gray-800'
                      }`}>
                        {getTeamTotal(team) > 0 ? formatToPar(getTeamToPar(team)) : '-'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Media Gallery */}
          <div className="bg-white rounded-xl p-5 shadow-lg">
            <h3 className="text-2xl font-bold mb-4 flex items-center gap-2">
              <Camera className="text-blue-600" />
              Photos & Videos
            </h3>
            {Object.keys(media).length === 0 ? (
              <p className="text-gray-500 text-center py-8">No media uploaded yet</p>
            ) : (
              <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
                {Object.entries(media).map(([key, items]) => {
                  const [team, hole, type] = key.split('-');
                  return items.map((item, idx) => (
                    <div key={`${key}-${idx}`} className="bg-gray-50 rounded-xl p-3">
                      <div className="flex items-center justify-between mb-2">
                        <span className="font-bold text-sm text-blue-700">{team}</span>
                        <span className="text-xs text-gray-500">Hole {hole}</span>
                      </div>
                      {item.data ? (
                        <>
                          {type === 'photo' ? (
                            <img
                              src={item.data}
                              alt={`${team} hole ${hole}`}
                              className="w-full h-48 object-cover rounded-lg mb-2"
                            />
                          ) : (
                            <video
                              src={item.data}
                              controls
                              className="w-full h-48 rounded-lg mb-2"
                            />
                          )}
                        </>
                      ) : (
                        <a
                          href={item.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-blue-600 hover:underline text-sm break-all block"
                        >
                          {type === 'photo' ? 'Photo' : 'Video'} - View {type}
                        </a>
                      )}
                      <p className="text-xs text-gray-500">
                        {new Date(item.timestamp).toLocaleString()}
                      </p>
                    </div>
                  ));
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
