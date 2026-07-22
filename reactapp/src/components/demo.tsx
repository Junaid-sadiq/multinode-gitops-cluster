import { ShaderAnimation } from "@/components/ui/shader-lines";
import { useState } from "react";

export default function DemoOne() {
  const [email, setEmail] = useState("");
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Handle newsletter signup here
    console.log("Email submitted:", email);
    setIsSubmitted(true);
    setTimeout(() => {
      setIsSubmitted(false);
      setEmail("");
    }, 3000);
  };

  return (
    <div className="relative flex h-screen w-full flex-col items-center justify-center overflow-hidden">
      <ShaderAnimation/>
      
      <div className="pointer-events-none z-10 flex flex-col items-center justify-center gap-8 px-4 max-w-4xl w-full">
        <h1 className="text-center text-5xl md:text-7xl leading-tight font-semibold tracking-tighter text-white drop-shadow-2xl">
          Launching Something Cool
          <br />
          Very Soon
        </h1>
        
        <p className="text-center text-xl md:text-2xl text-white/90 font-medium drop-shadow-lg">
          Sign Up for Newsletter
        </p>
        
        <form 
          onSubmit={handleSubmit} 
          className="pointer-events-auto flex flex-col sm:flex-row gap-3 w-full max-w-md"
        >
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Enter your email"
            required
            className="flex-1 px-6 py-4 rounded-full bg-white/10 backdrop-blur-md border border-white/20 text-white placeholder:text-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-white/40 transition-all"
          />
          <button
            type="submit"
            disabled={isSubmitted}
            className="px-8 py-4 rounded-full bg-white text-black font-semibold hover:bg-white/90 focus:outline-none focus:ring-2 focus:ring-white/50 transition-all disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap"
          >
            {isSubmitted ? "✓ Subscribed!" : "Notify Me"}
          </button>
        </form>
      </div>
    </div>
  )
}
