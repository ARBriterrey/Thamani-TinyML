import { useState, useEffect, useRef } from 'react';
import { Activity, Server, FileText, Database, Play, AlertCircle } from 'lucide-react';
import { format } from 'date-fns';

const API_URL = import.meta.env.VITE_API_URL || 'https://edge.thamanihc.com/api';

function App() {
  const [logs, setLogs] = useState([]);
  const [jobs, setJobs] = useState([]);
  const [serverStatus, setServerStatus] = useState('connecting');
  const logsEndRef = useRef(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Check health
        const healthRes = await fetch(`${API_URL}/health`);
        if (healthRes.ok) {
          setServerStatus('online');
        } else {
          setServerStatus('offline');
        }

        // Fetch logs
        const logsRes = await fetch(`${API_URL}/logs`);
        if (logsRes.ok) {
          const logsData = await logsRes.json();
          // The API returns a deque list, which is in reverse order (newest first).
          // We want to show oldest to newest top-to-bottom, so we reverse it.
          setLogs(logsData.logs.reverse());
        }

        // Fetch recent jobs
        const jobsRes = await fetch(`${API_URL}/jobs/recent`);
        if (jobsRes.ok) {
          const jobsData = await jobsRes.json();
          setJobs(jobsData.recent_jobs);
        }
      } catch (err) {
        setServerStatus('offline');
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 2000);
    return () => clearInterval(interval);
  }, []);

  // Auto-scroll logs to bottom
  useEffect(() => {
    if (logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [logs]);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-200 font-sans selection:bg-cyan-500/30">
      <div className="max-w-7xl mx-auto p-6 space-y-6">
        
        {/* Header */}
        <header className="flex items-center justify-between bg-slate-900/50 p-4 rounded-2xl border border-slate-800/50 backdrop-blur-xl">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-cyan-500/10 rounded-lg">
              <Activity className="w-6 h-6 text-cyan-400" />
            </div>
            <div>
              <h1 className="text-xl font-bold bg-gradient-to-r from-cyan-400 to-blue-500 bg-clip-text text-transparent">
                Thamani Server Dashboard
              </h1>
              <p className="text-sm text-slate-400">Real-time monitoring and orchestration</p>
            </div>
          </div>
          <div className="flex items-center space-x-2">
            <div className="flex items-center space-x-2 px-3 py-1.5 rounded-full bg-slate-800 border border-slate-700">
              <div className={`w-2.5 h-2.5 rounded-full ${
                serverStatus === 'online' ? 'bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]' :
                serverStatus === 'connecting' ? 'bg-amber-500 animate-pulse' :
                'bg-rose-500'
              }`} />
              <span className="text-sm font-medium capitalize text-slate-300">
                {serverStatus}
              </span>
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Logs View */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold flex items-center space-x-2">
                <Server className="w-5 h-5 text-slate-400" />
                <span>Live Server Logs</span>
              </h2>
              <div className="text-xs text-slate-500 px-2 py-1 bg-slate-900 rounded-md">
                Polling every 2s
              </div>
            </div>
            
            <div className="bg-[#0D1117] border border-slate-800 rounded-xl overflow-hidden h-[600px] flex flex-col font-mono text-sm relative shadow-2xl">
              <div className="flex items-center space-x-2 px-4 py-2 border-b border-slate-800 bg-slate-900/50">
                <div className="w-3 h-3 rounded-full bg-rose-500/20 border border-rose-500/50"></div>
                <div className="w-3 h-3 rounded-full bg-amber-500/20 border border-amber-500/50"></div>
                <div className="w-3 h-3 rounded-full bg-emerald-500/20 border border-emerald-500/50"></div>
                <span className="ml-2 text-xs text-slate-500">orchestrator.log</span>
              </div>
              
              <div className="flex-1 overflow-y-auto p-4 space-y-1 custom-scrollbar">
                {logs.length === 0 ? (
                  <div className="text-slate-500 italic text-center mt-10">
                    Waiting for logs...
                  </div>
                ) : (
                  logs.map((log, i) => (
                    <div key={i} className="flex space-x-4 hover:bg-slate-800/30 px-2 py-1 rounded transition-colors group">
                      <span className="text-slate-600 shrink-0 select-none">
                        {format(new Date(log.timestamp), 'HH:mm:ss.SSS')}
                      </span>
                      <span className={`shrink-0 font-semibold w-12 ${
                        log.level === 'INFO' ? 'text-cyan-400' :
                        log.level === 'ERROR' ? 'text-rose-400' :
                        log.level === 'WARNING' ? 'text-amber-400' :
                        'text-slate-400'
                      }`}>
                        {log.level}
                      </span>
                      <span className="text-slate-300 break-all whitespace-pre-wrap">
                        {log.message}
                      </span>
                    </div>
                  ))
                )}
                <div ref={logsEndRef} />
              </div>
            </div>
          </div>

          {/* Recent Jobs Sidebar */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold flex items-center space-x-2">
              <Database className="w-5 h-5 text-slate-400" />
              <span>Recent Jobs</span>
            </h2>
            
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-4 space-y-3 h-[600px] overflow-y-auto custom-scrollbar">
              {jobs.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full text-slate-500 space-y-2">
                  <FileText className="w-8 h-8 opacity-50" />
                  <p>No jobs processed yet</p>
                </div>
              ) : (
                jobs.map(job => (
                  <div key={job.job_id} className="bg-slate-950 border border-slate-800 rounded-lg p-3 hover:border-slate-700 transition-colors">
                    <div className="flex justify-between items-start mb-2">
                      <div className="font-mono text-xs text-cyan-400 break-all pr-2">
                        {job.job_id}
                      </div>
                      <div className={`px-2 py-0.5 rounded text-[10px] uppercase font-bold tracking-wider shrink-0 ${
                        job.status === 'completed' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' :
                        job.status === 'processing' ? 'bg-blue-500/10 text-blue-400 border border-blue-500/20' :
                        'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                      }`}>
                        {job.status}
                      </div>
                    </div>
                    
                    <div className="text-sm text-slate-400 space-y-1">
                      <div className="flex justify-between">
                        <span>Device:</span>
                        <span className="text-slate-200">{job.device_id || 'Unknown'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Started:</span>
                        <span className="text-slate-300 text-xs">
                          {format(new Date(job.received_at), 'HH:mm:ss')}
                        </span>
                      </div>
                    </div>

                    {job.result && job.result.risk_category && (
                      <div className="mt-3 pt-3 border-t border-slate-800">
                        <div className="flex justify-between items-center">
                          <span className="text-xs text-slate-500 uppercase tracking-wider font-semibold">Risk Level</span>
                          <span className={`text-sm font-bold ${
                            job.result.risk_category === 'HIGH' ? 'text-rose-500' :
                            job.result.risk_category === 'MODERATE' ? 'text-amber-500' :
                            'text-emerald-500'
                          }`}>
                            {job.result.risk_category}
                          </span>
                        </div>
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
      
      {/* Global styles for custom scrollbar embedded */}
      <style dangerouslySetInnerHTML={{__html: `
        .custom-scrollbar::-webkit-scrollbar {
          width: 8px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: rgba(15, 23, 42, 0.5);
          border-radius: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: rgba(51, 65, 85, 0.8);
          border-radius: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: rgba(71, 85, 105, 1);
        }
      `}} />
    </div>
  );
}

export default App;
